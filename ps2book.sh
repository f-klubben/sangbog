#!/bin/sh
# -*-perl-*-
#======================================================================#
# Run the right perl version:
if [ -x /usr/local/bin/perl ]; then
  perl=/usr/local/bin/perl
elif [ -x /usr/bin/perl ]; then
  perl=/usr/bin/perl
else
  perl=`which perl| sed 's/.*aliased to *//'`
fi

exec $perl -x -S $0 "$@"     # -x: start from the following line
#======================================================================#
#! /Good_Path/perl -w 
# line 17
#
# Name:   ps2book
# Author: wd (Wolfgang [.] Dobler [at] kis.uni-freiburg.de)
# Date:   3-Aug-2001
# Version: 0.71
# CVS $Id: ps2book,v 1.61 2007/07/12 17:12:28 dobler Exp $
# Description: See `ps2book -h' and `perldoc ps2book'
# Usage:  ps2book  [-s|--sort]  <file1> [<file2> ..]
#
# TO DO:
# - require 5.004 (if this is really true)
# - Catch errors like this one and don't tell you were successful:
#     no printcap for printer 'hp_stafff'
#     job 'cfA767mephisto.ncl.ac.uk' transfer to hp_stafff@localhost failed
#     Printed booklet on hp_stafff.
# - Make set of pages for -F option more configurable (e.g.`-F0.85:4-7'
#   [better] or `-F0.85 -b 4,5,6,7' [adds yet another option..])
# - Use File::Temp instead of POSIX::tmpnam

# Copyright 2001--2007 Wolfgang Dobler
# This file can be distributed under the same terms as Perl.

require 5;

use strict;

use Fcntl;
use File::Temp qw(tmpnam);
use IPC::Open2;			# for bidirectional pipe to the `file' command
use Getopt::Long;
# Allow for `-Plp' as equivalent to `-P lp' etc:
Getopt::Long::config("bundling");

my $enoughbytes=2000;		# Maximum size of header in PS file
my $gs='gs';

my (%opts);	# Variables written by GetOptions
my ($usage,$stdin,$cmdname,$cookie);
my ($debug,$printer,$display,$outfile);
my ($lpcmd,$lprflag,$gv,$tmpfile,$pstpstring,$redir);
my (@psbkargs,@pstpargs,@dest,@bb,@bb2);
my ($ppmm,$mwidth,$mheight,$mheight_2,$mwidth2,$iwidth,$iheight);
my ($scale,$dx,$dy,$xmidi,$ymidi,$xmido,$ymido0,$ymido1);
my ($xoff0,$yoff0,$xoff1,$yoff1,$xoff2,$yoff2,$xoff3,$yoff3,$twosideshift);
my ($opt,$file,$ofile,$os,$ps,$nsubs,$bb,$fmt,$scfmt,$bfa,$bfe);
my $doll='\$';			# Need this to trick CVS


# Usage summary:
$cmdname = (split('/', $0))[-1];
$usage =
"Usage:  $cmdname [options] file1 [file2 ..]
        $cmdname [options] < file1
Options:
  -h
  --help             \tShow usage overview
  -b
  --brief            \tOnly show a one-line message for each processed
                     \tfile
  -q
  --quiet            \tDon't show output from psbook and pstops
  -o <file>
  --output=<file>    \tWrite output to file <file> (allows for only one
                     \tinput file)
  -P<printer>
  -d<printer>        \tSend output to <printer> (or to gv/ghostview)
  -p <paper>         \tSpecify input page size (`a4', `letter', or `letter-bk')
  -m <paper>         \tSpecify output medium (`a4' or `letter')
  -s <sig>
  --signature=<sig>  \tSet signature size. Must be a multiple of 4, see
                     \t`man psbook'
  -2
  --2up              \tDon't print signatures but just 2 pages in 2up
                     \tformat. Useful if you don't have a duplex printer
  -t
  --tumble           \tTumble page (tells printer to tumble)

  -T
  --force-tumble     \tTumble page even if printer refuses to

  -f <ff>
  --fillfactor=<ff>  \tMaximum page filling factor in width and height
                     \t(based on PostScript bounding box)
  -F <ff>
  --bbfillfact=<ff>  \tLike -f, but determines the bounding box using
                     \tghostscript's bbox device
  -n
  --nocookie         \tDon't insert the PostScript duplex cookie. The
                     \tdefault is to add it to the output files, so
                     \tthey are automatically printed double-sided on a
                     \tduplex-capable printer
  -c
  --clip             \tApply clipping (use pstops's default clipping box)

  -x
  --noclip           \tAvoid clipping (use huge clipping box) [default]

  --unsafe           \tDon't use ghostscript's -dSAFER option [helps with some
                     \tEPS ghostscript bug, but should be avoided otherwise]

  -v
  --version          \tPrint version number and quit
See `perldoc $cmdname' for a more comprehensive documentation.\n";

## Prepend options from environment variable PS2BOOK_OPTIONS if set
if (defined($ENV{PS2BOOK_OPTIONS})) {
    unshift @ARGV, split(/\s+/, $ENV{PS2BOOK_OPTIONS});
};
## Process command line
GetOptions(\%opts,
	   qw( -h   --help
	       -b   --brief
	       -q   --quiet
	            --debug
	       -P=s -d=s
	       -o=s --output=s
	       -s=i --signature=i
	       -2   --2up
               -t   --tumble
               -T   --force-tumble
	       -f=f --fillfactor=f
	       -F=f --bbfillfact=f
	       -p=s --pagesize=s
	       -m=s --medium=s
	       -n   --nocookie
               -v   --version
               -c   --clip
               -x   --noclip
                    --unsafe
             ));

if ($opts{'debug'}) { $debug = 1 } else { $debug = 0 }
if ($debug) {
    foreach $opt (keys(%opts)) {
	print "\$opts{$opt} = `$opts{$opt}'\n";
    }
    print "\@ARGV = `@ARGV'\n";
}

if ($opts{'h'} || $opts{'help'}) { die $usage; }
if ($opts{'v'} || $opts{'version'}) {
    my $rev = '$Revision: 1.61 $';
    my $date = '$Date: 2007/07/12 17:12:28 $';
    $rev =~ s/${doll}Revision:\s*(\S+).*/$1/;
    $date =~ s/${doll}Date:\s*(\S+).*/$1/;
    die "$cmdname version $rev ($date)\n";
}
if (($opts{'o'} || $opts{'output'}) && (@ARGV>1)) {
    die "You can't use `-o' with more than one file.\n"; }
my $quiet    = ($opts{'q'} || $opts{'quiet'}        || '');
my $brief    = ($opts{'b'} || $opts{'brief'}        || '');
my $sig      = ($opts{'s'} || $opts{'signature'}    || 0 );
my $twoup    = ($opts{'2'} || $opts{'2up'}          || 0 );
my $tumble   = ($opts{'t'} || $opts{'tumble'}) ? "false" : "true";
my $Tumble   = ($opts{'T'} || $opts{'force-tumble'} || 0 );
my $ff       = ($opts{'f'} || $opts{'fillfactor'}   || 0 );
my $FF       = ($opts{'F'} || $opts{'bbfillfact'}   || 0 );
$ff ||= $FF;			# set $ff for -F option, too
my $medium   = ($opts{'m'} || $opts{'medium'}       || get_papersize() );
my $page     = ($opts{'p'} || $opts{'pagesize'}     || '');
my $nocookie = ($opts{'n'} || $opts{'nocookie'}     || '');
my $noclip   = ($opts{'x'} || $opts{'noclip'}       || '');
my $clip     = ($opts{'c'} || $opts{'clip'}         || ! $noclip);
my $unsafe   = (              $opts{'unsafe'}       || '');

$medium = lc($medium);
print "Opts: \$medium = <$medium>, \$page=<$page>\n" if ($debug);

unless ($unsafe) {
    $gs = "$gs -dSAFER";  # Use the SAFER option with ghostscript
}

# Set up options for gv < 3.6 (gv35), gv>3.6 (gv), and ghostview (ghv)
my @ghostcommon = (); # common options for gv and ghostview
my @gvmedium   = ("--media=$medium", '--scale=-1');
my @gv35medium = ('-media', $medium, '-magstep', '-1');
my @ghvwmedium = ("-$medium", "-magstep", "-1");
#
my @gvlandscape   = ('--orientation=landscape');
my @gv35landscape = ('-landscape');
my @ghvlandscape  = ('-landscape');
#
my @gvopts   = (@gvmedium,   @ghostcommon, @gvlandscape,   "-antialias"); # gv
my @gv35opts = (@gv35medium, @ghostcommon, @gv35landscape, "-antialias"); # gv < 3.6
my @ghvwopts = (@ghvwmedium, @ghostcommon, @ghvlandscape); # ghostview

# Map -d onto -P
$printer = ($opts{'P'} || $opts{'d'} || $ENV{PS2BOOK_PRINTER} || '');
# -o overwrites -P
if ($ofile = ($opts{'o'} || $opts{'output'} || '')) {
    $printer = '';
}

if (@ARGV) {			# file name given
    $stdin = 0;
} else {			# reading from stdin
    $stdin = 1;
    $ofile = ($ofile || "stdin_book.ps") unless $printer;
    push @ARGV, "<stdin>";
}


# The PostScript duplex cookie:
# Michael's cookie:
#$cookie = "statusdict begin true setduplexmode end\n";
# Same with tumbling:
#$cookie = "statusdict begin true setduplexmode true settumble end\n";
# My cookie from the web:
#$cookie =
#    "%%BeginFeature: *Duplex True\n" .
#    "<< /Duplex true >> setpagedevice\n" .
#    "%%EndFeature\n" .
#    "%%BeginFeature: *Tumble True\n" .
#    "<< /Tumble true >> setpagedevice\n" .
#    "%%EndFeature\n";
# My variant of Akim Demaille's cookie (a2ps):
#$cookie = <<"END_OF_COOKIE";
#%%BeginFeature: *Duplex DuplexTumble
#mark
#{
#  << /Duplex true /Tumble true >> setpagedevice
#} stopped
#cleartomark
#%%EndFeature
#END_OF_COOKIE
# Akim Demaille's variant is still better (not spoilt by pstops)
$cookie = <<"END_OF_COOKIE";
%%BeginFeature: *Duplex DuplexTumble
mark
{
  (<<) cvx exec /Duplex (true) cvx exec /Tumble ($tumble) cvx exec (>>) cvx exec
  systemdict /setpagedevice get exec
} stopped
cleartomark
%%EndFeature
END_OF_COOKIE


# Check for availability of `pstops' and `psbook'
unless (in_PATH("pstops")) { die "Can't find `pstops'"; }
unless (in_PATH("psbook")) { die "Can't find `psbook'"; }

# Bold face to terminals only
if (-t STDOUT) {	# if STDOUT is connected to a terminal
    $bfa = "[1m"; $bfe = "[0m";
} else { $bfa = ""; $bfe = ""; }

# Use the right print/display command:
$display = 0;
if ($printer) {
    $display = ($printer =~ /\s*display\s*/i);
    if ($display) {		# Output to postscript viewer
	if (in_PATH("gv")) {
	    $gv = "gv";
            if (get_gv_version($gv) < 3.06) {
                @gvopts = @gv35opts; # Overwrite these
            }
	} elsif (in_PATH("ghostview")) {
	    $gv = "ghostview";
	    @gvopts = @ghvwopts; # Overwrite these
	} else {
	    die "Don't know how you can live without gv and ghostview.";
	}
    } else {			# Output to printer
	$os = `uname`;
	if ($os =~ /^(Linux|OSF1|SunOS)$/) {
	    $lpcmd = 'lpr';
	    $lprflag = '-P';
	} elsif ($os =~ /^(HP-UX|IRIX64)$/) {
	    $lpcmd = 'lp';
	    $lprflag = '-d';
	} else {
	    die "Don't know how to print under `$os'.";
	}
    }
}

# set huge width and height for $noclip
my @clipargs;
@clipargs = ("-w10000", "-h10000") unless ($clip);

## Determine layout geometry
$ppmm = 72/25.4;		# Points per mm: 1pt = 1/72 in;  1in = 2.54cm

## Output medium size:
if ($medium eq 'a4') {
    $mwidth  = 210;		# [mm]
    $mheight = $mwidth*sqrt(2);
} elsif ($medium eq 'letter') {	# 8.5"×11"
    $mwidth  = 215.9;		# [mm]
    $mheight = 279.4;		# [mm]
} else {
    die "Unknown medium <$medium>, try `-m a4'. \n"
      . "Aborting.\n";
}
$mheight_2 = $mheight/2;
print STDERR "\$medium = <$medium> -> ($mwidth, $mheight)\n" if ($debug);

if ($display) { $tmpfile = tmpnam() }; # open temporary file


## Now work
local undef $/;			# Slurp in whole files
File: foreach $file (@ARGV) {

    # Arguments for psbook and pstops
    @psbkargs = ();
    @pstpargs = ();

    # Print diagnostic message..
    print STDERR "$file: " unless $quiet;
    # ..and then set $file to its true value
    if ($stdin) { $file = "-" };
    # Determine file name for output
    if ($printer) {
	$outfile='';
    } else {
	if ($ofile) {
	    $outfile = $ofile;
	} else {
	    $outfile = $file;
	    $outfile =~ s/\.gz$//; # remove gzip suffix
	    $outfile =~ s/(\.+[^\.]*|$)$/_book$1/;
	    die "Problem with file name <$file>\n"
	        if ($outfile eq $file); # never overwrite original file
	}
    }
    if (!open(INPUT, "< $file")) {
        print STDERR "Can't open input file $file\n";
        next File;
    }
    ## Read and process check the data
    $ps = <INPUT>; close(INPUT);
    # Check for `%!' cookie
    my $bad_ps = 0;
    if (substr($ps,0,2) ne '%!' ) {
	# Maybe a compressed PostScript file? -- Check for gzip cookie.
	# Can't use the `file' command, since on SunOS, IRIX or OSF1 it
	# does not support `file -' and the OSF1 version doesn't recognize
	# gzip format at all.
	if (substr($ps,0,4) eq "\037\213\010\010") {
	    $ps = read_gzipped($ps,$file);
	    # Is it PostScript now?
	    if (substr($ps,0,2) ne '%!' ) {
		$bad_ps = 1;
	    }
	} else {
	    $bad_ps = 1;
	}
    }
    if ($bad_ps) {		# Neither PS nor gzipped PS
	print STDERR "$file is not a PostScript file\n";
	next File;
    }

    ## Get and process (input) page format from file unless given by cmd
    ## line option
    ($iwidth,$iheight) = (0,0);	# default (will be set below, or not used)
    if (! $ff) {
	# Don't need page size when using BoundingBox, unless we tumble
	# [not sure what this will do to clipping box..]
	$page = ( $page || get_page_size($medium) );
	$page = lc($page);
	if ($page eq 'a4') {
	    $iwidth  = 210;		# [mm]
	    $iheight = $iwidth*sqrt(2);
	} elsif ($page eq 'letter') {
	    $iwidth  = 215.9;		# [mm]
	    $iheight = 279.4;		# [mm]
	} elsif ($page eq 'letter-bk') {
	    $iwidth  = 197.57;		# [mm]
	    $iheight = 305.33;		# [mm]
	} else {
	    if ($ff) {
	    } else {
		die
		  "Unknown page size <$page>, try `-p a4'.\n"
		  . "Aborting.\n";
	    }
	}
	print STDERR "\$page = <$page> --> ($iwidth, $iheight)\n" if ($debug);

	# Adapt clipping box
	if ($clip) {
	    @clipargs = ( sprintf("-w%-1.2f",$iwidth *$ppmm) ,
			  sprintf("-h%-1.2f",$iheight*$ppmm) );
	}

	# Map input file page size to bounding box for unified treatment later:
	@bb = (0, 0, $iwidth*$ppmm, $iheight*$ppmm);
    }

    ## Construct arguments for psbook and pstops
    if ($quiet || $brief) {
	push @psbkargs, '-q';
	push @pstpargs, '-q';
    }
    if ($sig) { push @psbkargs, "-s$sig" };
    # Redirecting stderr in the pipe command:
    if ($quiet || $brief) { $redir = '2> /dev/null' } else { $redir = '' }
    # Output destination:
    if ($outfile) {		# write to file
	@dest = ('>', "$outfile");
    } elsif ($display) {        # send to gv
	@dest = ('>', "$tmpfile");
    } else {			# send to printer
	@dest = ('|', "$lpcmd", "$lprflag$printer");
    }

    ## Get bounding box from file.
    ## @bb is the bounding box for odd pages (and is used for calculating
    ## the scale factor); @bb2 that for even pages.
    if ($ff) {			# If $ff is given, overwrite $pstpstring
	if ($FF) {		# Extract bounding box via `gs -sDEVICE=bbox'
	    @bb = get_bbox($ps);
	    @bb2 = @bb[4,5,6,7];
	    @bb  = @bb[0,1,2,3]; # @bb is now @bbodd
	} else {		# Read bounding box comment from PS text
	    # Read from first $enoughbytes bytes
	    $bb = '';
	    # Try %%BoundingBox first
	    ($bb) = (substr($ps,0,$enoughbytes) =~ /\n(%%BoundingBox[^\r\n]*)/);
	    # .. and %%PageBoundingBox next
	    unless ($bb) {
		($bb) = (substr($ps,0,$enoughbytes)
			 =~ /\n(%%PageBoundingBox[^\r\n]*)/);
	    }
	    if ($bb) {
		(undef, @bb) = split(/\s+/, $bb);
	    } else {
		printf STDERR "Warning: Can't get bounding box for $file\n"
		  unless $quiet;
		next File;
	    }
	    @bb2 = @bb;
	}
    } else {
	@bb2 = @bb;
    }

    if ($debug) {
	print STDERR "\@bb  = (@bb)\n";
	print STDERR "\@bb2 = (@bb2)\n";
    }

    ## Construct pstops geometry settings.
    ## Assumes that odd and even page bboxes are vertically aligned.
    ## Algorithm is quite simple: locate the centers of the bounding boxes
    ## after rotation and scaling and shift the to centers of half-pages.
    $dx = ($bb[2]-$bb[0])/$ppmm;
    $dy = ($bb[3]-$bb[1])/$ppmm;
    $xmidi = ($bb[0]+$bb[2])/$ppmm/2; # x position of center of input bbox
    $ymidi = ($bb[1]+$bb[3])/$ppmm/2; # y position of center of input bbox
    if ($debug) { print "\n\@bb = @bb\n" };
    $scale = min($mheight_2/$dx,$mwidth/$dy);
    if ($ff) { $scale = $scale*$ff };

    $xmido = $mwidth/2;		# x position of center of output half pages
    $ymido0 = 0.25*$mheight;	# y position of center of output lower half page
    $ymido1 = 0.75*$mheight;    # y position of center of output upper half page
    $xoff0 = $xmido + $ymidi*$scale;
    $yoff0 = $ymido0 - $xmidi*$scale;
    $xoff1 = $xoff0;
    $yoff1 = $ymido1 - $xmidi*$scale;

    # For $Tumble option:
    my $yoffbb = $iheight - 2*$ymidi*0;	# correct for horizontally
                                        # non-centred bboxes
    $xoff2 = $xmido  - $ymidi*$scale;
    $yoff2 = $ymido1 + $xmidi*$scale;
    $xoff3 = $xoff2;
    $yoff3 = $ymido0 + $xmidi*$scale;

    # Correct for horizontal shift of bboxes between odd and even pages:
    $twosideshift = $scale*($bb2[0]-$bb[0])/$ppmm;
    print "\$twosideshift = $twosideshift\n" if ($debug);
    if ($twoup) {
	$yoff1 -= $twosideshift;
	$yoff3 += $twosideshift;
    } else {
	$yoff0 -= $twosideshift;
	$yoff2 += $twosideshift;
    }

    if ($debug) {
	print "\$scale = $scale\n";
	print "(\$xoff0, \$yoff0) = ($xoff0, $yoff0)\n";
	print "(\$xoff1, \$yoff1) = ($xoff1, $yoff1)\n";
	if ($Tumble) {
	    print "(\$xoff2, \$yoff2) = ($xoff2, $yoff2)\n";
	    print "(\$xoff3, \$yoff3) = ($xoff3, $yoff3)\n";
	}
    }
    # Use sprintf to enforce fixed point notation (as needed by pstops)
    $scfmt = '%.5f';
    $fmt   = '%.3f';
    if ($Tumble) {
	$pstpstring = sprintf("'4:0L\@$scfmt(${fmt}mm,${fmt}mm)" .
			      "+1L\@$scfmt(${fmt}mm,${fmt}mm)"   .
			      ",2R\@$scfmt(${fmt}mm,${fmt}mm)"   .
			      "+3R\@$scfmt(${fmt}mm,${fmt}mm)'",
			      $scale, $xoff0, $yoff0,
			      $scale, $xoff1, $yoff1,
			      $scale, $xoff2, $yoff2,
			      $scale, $xoff3, $yoff3);
    } else {
	$pstpstring = sprintf("'2:0L\@$scfmt(${fmt}mm,${fmt}mm)" .
			      "+1L\@$scfmt(${fmt}mm,${fmt}mm)'",
			      $scale, $xoff0, $yoff0,
			      $scale, $xoff1, $yoff1);
    }
    @pstpargs = (@pstpargs, @clipargs, $pstpstring);

    ## Splice the cookie in
    unless ($nocookie) {
	# Dvips produces PostScript without `%%BeginProlog', which then
        # causes pstops to squeeze something before my cookie and duplex
        # printing does not work (with the `/Duplex true etc.' cookie).
        # B.t.w: this was not a problem with the `statusdict' cookie.

	## This does not work if some included eps figures contain
	## %%BeginProlog--%%EndProlog pairs:
        #        if ($ps !~ /(\n|\r)%%BeginProlog/) { $cookie .= "%%BeginProlog\n" };
	## With this, we might easily end up with two %%BeginProlog lines:
#	$cookie .= "%%BeginProlog\n";
#	$ps =~ s/((\n|\r)%%End(Comments|Prolog))/$1\n$cookie%/;
	## Try several places, starting with preferred ones:
	$nsubs = ($ps =~ s/(?:\n|\r)(%%EndSetup)/\n$cookie$1/);
	unless ($nsubs) {	# Just after '%%EndProlog'
	    $nsubs = ($ps =~ s/(?:\n|\r)(%%EndProlog)(?:\n|\r)/\n$1\n$cookie/);
	}
	unless ($nsubs) {	# In desperation try just before '%%Page: 1 1'
	    $nsubs = ($ps =~ s/(?:\n|\r)(%%Page:\s)/\n$cookie$1/);
	}
	unless ($nsubs) {
	    print STDERR
		"WARNING: No cookie inserted (no `%%EndSetup' found)\n";
	}
    }

    ## Now start the machinery
    my $cmdline;
    if ($twoup) { 		# no psbook needed
	$cmdline = "| pstops @pstpargs @dest $redir";
    } else {
	$cmdline = "| psbook @psbkargs | pstops @pstpargs @dest $redir";
    }
    print "\nCommand line: $cmdline\n" if ($debug);
    open(OUTPUT, "$cmdline");
    print OUTPUT $ps; close(OUTPUT);

    if ($display) {		# So far the result is only in $tmpfile
	if ($debug) {
	    print "\nCommand line: $gv @gvopts $tmpfile\n";
	}
	system($gv, @gvopts, $tmpfile);
	unlink("$tmpfile") or die "Can't unlink temporary file $tmpfile";
    }
    if (!$quiet) {
	if ($outfile) {
	    print "Wrote file in booklet format to $bfa$outfile$bfe\n";
	} elsif (!$display) {
	    print "Printed booklet on $printer.\n";
	}
    }
}

exit;

# --------------------------------------------------------------------- #
sub min {
# Numerical minimum
    ($a, $b) = @_;
    if ($a+0 < $b+0) {
	$a;
    } else {
	$b;
    }
}
# --------------------------------------------------------------------- #
sub max {
# Numerical maximum
    ($a, $b) = @_;
    if ($a+0 > $b+0) {
	$a;
    } else {
	$b;
    }
}
# --------------------------------------------------------------------- #
sub in_PATH {
# Check whether an executable is available in the execution PATH
    my $file = shift;

    my $path;
    foreach $path (split(/:/,$ENV{PATH})) {
	if (-x "$path/$file") { return 1; }
    }
    return 0;
}
# --------------------------------------------------------------------- #
sub read_gzipped {
# Read data from $file and gunzip them
    my $gz_ps = shift;
    my $file = shift;

    print STDERR "Compressed file $file\n" unless ($quiet || $brief);
    if ($debug) { print STDERR "Opening gzip\n" }
    my $pid = open2(\*UNGZIPPED,\*GZIPPED,"gzip -cd");
    # Fork off a child process to allow simultaneous reading and
    # writing -- otherwise files of 100 kB or more cause a
    # deadlock.
    if (my $fid=fork) {	# parent
	close GZIPPED;	# don't forget this one
	if ($debug) { print STDERR "Parent: Reading from gzip\n" }
	$ps = <UNGZIPPED>;
	close UNGZIPPED; # not necessary, I guess
	if ($debug) { print STDERR "Parent: Read from gzip\n" }
	waitpid($fid,0); # not really needed her, but avoids zombies
	if ($debug) { print STDERR "Parent: Child has finished\n" }
    } else {		# child
	die "Cannot fork: $!" unless defined ($fid);
	if ($debug) { print STDERR "Child: Writing to gzip (pid $pid)\n" }
	close UNGZIPPED; # apparently not necessary
	print GZIPPED $gz_ps;
	close GZIPPED;
	if ($debug) { print STDERR "Child: Wrote to gzip\n" }
	exit;
    }
    $ps;			# return decompressed data
}
# --------------------------------------------------------------------- #
sub get_papersize {
# Get paper size from all kinds of sources:

    # PAPERCONF env. variable
    print STDERR "get_papersize: Trying PAPERCONF\n" if $debug;
    $medium = $ENV{PAPERCONF};

    # File pointed to by PAPERSIZE env. variable, or /etc/papersize
    unless ($medium) {
	my $psizefile = ($ENV{PAPERSIZE} || '/etc/papersize');
	print STDERR "get_papersize: Trying $psizefile\n" if $debug;
	if (-r $psizefile) {
	    if (open(PAPERSIZE,"< $psizefile")) {
		while (<PAPERSIZE>) {
		    next if /^\s*(#.*)?$/; # skip comment and empty lines
		    ($medium) = /^\s*(\S+)/ and last;
		}
	    } else {
		warn "Can't open file $ENV{PAPERSIZE}: $!\n";
	    }
	}
    }

    # LC_PAPER
    unless ($medium) {
	print STDERR "get_papersize: Trying LC_PAPER env. variable\n" if $debug;
	## Try to map locale names onto paper size
	if ($ENV{LC_PAPER}) {
	    $medium = $ENV{LC_PAPER};
	    ## Try to map common locale names onto paper types
	    if (   ($medium =~ /^[a-z]{2}_[A-Z]{2}/) # classical locale name
		|| ($medium =~ /^[a-z]{2}\s*$/)) { # short name like de
		if ($medium =~ /^_(US|CA)/) {
		    $medium = 'letter';
		} else {
		    $medium = 'a4';
		}
	    }
	}
    }

    # Last resort: default to 'a4'
    unless ($medium) {
	print STDERR "get_papersize: Defaulting to a4 paper\n" if $debug;
	$medium = 'a4';
    }

    # Canonicalize:
    $medium = lc($medium);
}
# --------------------------------------------------------------------- #
sub get_page_size {
# Try to infer input page size from file contents in $ps (so the file must
# have been read in by now).

    my $medium = shift;

    # Only try first $enoughbytes bytes (up to first occurence of
    # `%%EndSetup'), assuming that a PostScript header will never be
    # longer than that
    my $ps_header = substr($ps,0,$enoughbytes);
    $ps_header =~ s/^(%%EndSetup).*/$1\n/ms;
    my $psize = '';
    ($psize) = ( $ps_header =~ /\n%%DocumentMedia: *(\S+)/ ) unless ($psize);
    ($psize) = ( $ps_header =~ /\n%%BeginPaperSize: *(\S+)/) unless ($psize);

    # If we find nothing, assume input page size is same as output medium
    # size
    $psize || $medium;
}
# --------------------------------------------------------------------- #
sub get_bbox {
# Use ghostscript's bbox device to get real bounding box of some pages
    my $ps = shift;

    my @pages1 = (3,5);	    # Needs to be configurable from cmd line later
    my @pages2 = (2,4);

    unless (in_PATH("gs"))       { die "Can't find `gs'";       }
    unless (in_PATH("psselect")) { die "Can't find `psselect'"; }

    my $psselect_cmd1 = "psselect -q -p" . join(',',@pages1);
    my $psselect_cmd2 = "psselect -q -p" . join(',',@pages2);
    warn "Using gs without -dSAFER -- please avoid doing this\n" if ($unsafe);
    my $gs_cmd = "$gs -q -sDEVICE=bbox -r600 -dNOPAUSE - -c quit";

    # Odd pages:
    my $cmd = "$psselect_cmd1 | $gs_cmd 2>&1";
    print STDERR "Opening psselect/gs:\n  | $cmd |\n" if ($debug);
    my @bb1 = get_bbox_rwpipe($cmd);
    print STDERR "Found \@bb1 = (", join(',',@bb1),")\n" if ($debug);

    # Even pages:
    $cmd = "$psselect_cmd2 | $gs_cmd 2>&1";
    print STDERR "Opening psselect/gs:\n  | $cmd |\n" if ($debug);
    my @bb2 = get_bbox_rwpipe($cmd);
    print STDERR "Found \@bb2 = (", join(',',@bb2),")\n" if ($debug);

    unless (@bb1 || @bb2) {
        die <<'DEAD_PARROT';

Couldn't get Bounding boxes from ghostscript. Run ps2book with the --debug
flag to see gs' output.
[I have found this with ESP ghostscript 7.07.1, where
   sh -c 'gs -dSAFER -sDEVICE=bbox'
 fails with
   Unrecoverable error: configurationerror in setpagedevice
 in that case, you can try using ps2book's --unsafe option.
]
DEAD_PARROT
    }
    # Defaults for short documents
    if (@bb1 and ! @bb2) {
	warn "No bbox found for even pages, using geometry of odd pages\n";
	@bb2 = @bb1;
    }
    if (@bb2 and ! @bb1) {
	warn "No bbox found for odd pages, using geometry of even pages\n";
	@bb1 = @bb2;
    }

    return (@bb1,@bb2);

}
# --------------------------------------------------------------------- #
sub get_bbox_rwpipe {
# Fork off a child process to allow simultaneous reading and writing to
# `psselect | gs' pipe -- otherwise files of 100 kB or more cause a
# deadlock.
    my $cmd = shift;

    my $pid = open2(\*BBOXOUT,\*BBOXIN,"$cmd");
    my @bblist;
    # EPS ghostscript 8.15.1 chokes on setting /Duplex (as pdftops does)
    # in connection with the bbox device, so we remove this:
    $ps =~ s|{ /Duplex true def }|{ }|;
    unless (my $fid=fork) {	# child
	die "Cannot fork: $!" unless defined ($fid);
	if ($debug) {
	    print STDERR "Child: Writing to psselect | gs (pid $pid)\n";
	}
	close BBOXOUT; # apparently not necessary
	print BBOXIN $ps;
	close BBOXIN;
	if ($debug) { print STDERR "Child: Wrote to psselect | gs\n" };
	exit;
    } else {			# parent
	close BBOXIN;	# don't forget this one
	if ($debug) { print STDERR "Parent: Reading from psselect | gs\n" }
	local $/ = "\n";
	while (<BBOXOUT>) {
	    if (/^%%BoundingBox:\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)/) {
		push @bblist, [$1, $2, $3, $4];	# accumulate accross pages
	    }
            print STDERR "BBOXOUT: $_" if ($debug);
	}
	close UNGZIPPED; # not necessary, I guess
	if ($debug) { print STDERR "Parent: Read from psselect | gs\n" }
	waitpid($fid,0); # not really needed her, but avoids zombies
	if ($debug) { print STDERR "Parent: Child has finished\n" }
    }

    ## Extract maximum bounding box
    return () unless (@bblist);

    my $infty = 10000;		# initialize bbox to be extremely empty
    my ($left,$bot,$right,$top) = ($infty,$infty,-$infty,-$infty);
    foreach my $bbref (@bblist) {
	$left  = min($left, $$bbref[0]);
	$bot   = min($bot,  $$bbref[1]);
	$right = max($right,$$bbref[2]);
	$top   = max($top,  $$bbref[3]);
    }

    return ($left, $bot, $right, $top);
}
# --------------------------------------------------------------------- #
sub get_gv_version {
# Determine gv version we are running. Important, because the switches
# have changed a lot -- even the one to get the version number (from `-v'
# pre-3.6 to `-[-]version' from 3.6 on.
    my $gv = shift;

    my ($version,$num_version);

    # Try >= 3.6 first
    if (`$gv --version 2> /dev/null` =~ /^gv\s+([0-9.]+)/) {
        $version = $1;
    } elsif (`$gv -v 2> /dev/null` =~ /^gv\s+([0-9.]+)/) {
        $version = $1;
    } else {
        warn "Cannot determine gv version; assuming 99.9\n";
        $version = '99.9';
    }

    # Numerical version (can be compared numerically).
    # Maps 3.6.2 to 3.0602, etc.
    # Implicit assumption: there will never be more than two digits in any
    # of the sub-version numbers, i.e. 3.5.8, 12.88.75 are OK, but 3.5.101
    # would seriously screw our numerical comparison.
    if ($version =~ /([0-9]+)\.([0-9]+)(?:\.([0-9])+)/) {
        my $major = $1;
        my $minor = $2;
        my $sub   = $3;

        $num_version = $major + $minor/100 + $sub/10000;
    }

    return $num_version;
}
# --------------------------------------------------------------------- #


__END__

=head1 NAME

B<ps2book> - Format a PostScript file as booklet using psbook and pstops

=head1 SYNOPSIS

B<ps2book> [B<-bhnqtvcx>] [B<-P>|B<-d> I<printer>]
[B<-f> I<ff>] [B<-F> I<ff>]
[B<-p> I<paper>] [B<-m> I<paper>] [B<-s> I<sig>] [B<-o> I<outfile>]
I<file1> [I<file2> [..]]


=head1 DESCRIPTION

B<ps2book> reads one or several (plain or gzipped) PostScript files and
rearranges the pages into a booklet.  It is essentially a nontrivial
wrapper around the two utilities psbook(1) and pstops(1) by Angus Duggan.

If no file is given, B<ps2book> acts as a filter on I<stdin> and
writes the result to I<stdin_book.ps> (or sends it to the printer if
this was specified).

By default, a PostScript duplex `cookie' is inserted into the file, so
it will print in duplex mode on PostScript printers which are capable
of doing so.

Even if input files are gzipped, the output is always uncompressed.


=head1 OPTIONS

=over 4

=item B<-h>, B<--help>

Show usage overview

=item B<-b>, B<--brief>

Show only a one-line message for each processed file

=item B<-q>, B<--quiet>

Don't show output from psbook and pstops

=item B<-o> I<file>, B<--output>=I<file>

Write output to I<file> (allows for only one input file).
The default output file name is the original one with `_book' spliced in
before the suffix. Thus, without the `-o' option, I<text.ps> would become
I<text_book.ps>.

=item B<-P> I<printer>, B<-d> I<printer>

Send output to I<printer>. Like with B<a2ps>, specifying the printer
I<display> starts up B<gv>/B<ghostview> to preview the result.

=item B<-p> I<paper>, B<--pagesize>=<paper>

Use I<paper> as input page size of the Postscript file(s).
Supported values are `a4', `letter' and `letter-bk' (letter booklet format
-- the format that when rotated and scaled by 0.707 will exactly fit on half
a letter page).

=item B<-m> I<paper>, B<--medium>=<paper>

Use I<paper> as output paper size. Supported values are `a4' and `letter'.

=item B<-s> I<sig>, B<--signature>=I<sig>

Set signature size to I<sig>, which must be a multiple of 4.
See psbook(1) for details.

=item B<-2>, B<--2up>

Don't print signatures but just 2 pages in 2up format.
Useful if your document has only two pages, or if you don't
have a duplex printer, but still want to use options like `-F'.

=item B<-t>, B<--tumble>

Tumble page (asks printer to do it). You won't see an effect
with ghostscript.

=item B<-T>, B<--force-tumble>

Tumble page without relying on the printer. You will see the effect
with ghostscript.

=item B<-f> I<ff>, B<--fillfactor>=I<ff>

Set (linear) fill factor to I<ff>. The fill factor defines the size of the
bounding box relative to the medium size (see section PAPER SIZE).

If x and y dimensions lead to different magnification factors, the smaller
one is chosen.
Thus, with a fill factor of 1.0, the bounding box will fill the whole page
in at least one direction.

Requires the document to have a C<%%BoundingBox:> or at least a
C<%%PageBoundingBox:> for the first page.

=item B<-F> I<ff>, B<--bbfillfact>=I<ff>

Like B<-f>, but determines the bounding box using ghostscript's C<bbox>
device.
Currently uses pages 2-5 for determining the bounding box, but this will
become switchable.

=item B<-n> B<--nocookie>

Do not insert the PostScript duplex `cookie'. Make sure to print the file
in a duplex queue if you use this option.

=item B<-c> B<--clip>

Apply page clipping (uses pstops's default clipping box).

=item B<-x> B<--noclip>

Avoid clipping of pages (use huge clipping box). Useful if you create a
centerfold page as an overwide page followed by an empty one.

This is also needed with some paper sizes, so it is now the default
setting and this option will disappear in the future.

=item B<--unsafe>

Don't use ghostscript's -dSAFER option.
This option should be avoided, but it is sometimes necessary to keep EPS
ghostscript 7.07.1 from choking with `B<ps2book -F> I<ff>'.

=item B<-v>, B<--version>

Show version number.

=back


=head1 PAPER SIZE

The page size of the input file is determined in the following order

=over 4

=item 1.
Command line option B<-p>/B<--pagesize>;

=item 2.
try to extract from the PostScript file (C<%%DocumentMedia:> [a2ps]
or C<%%BeginPaperSize> [dvips]);

=item 3.
use the medium size.

=back

The paper or medium size for printing is determined in the following order:

=over 4

=item 1.
Command line option B<-m>/B<--medium>;

=item 2.
environment variable B<PAPERCONF>;

=item 3.
the file specified by environment variable B<PAPERSIZE>;

=item 4.
the file F</etc/papersize>;

=item 5.
the environment variable B<LC_PAPER>;

=item 6.
choose `a4' as default.

=back


=head1 ENVIRONMENT

=over 4

=item B<PS2BOOK_PRINTER>

Set the default printer to use; will be overwritten by  the B<-P> option.
If neither B<PS2BOOK_PRINTER> nor the B<-P> option are set, output is
to a file.

As with B<-P>, the virtual printer I<display> previews the output via
B<gv>/B<ghostview>.

=item B<PS2BOOK_OPTIONS>

Options to be prepended to the command-line options.
E.g.

  export PS2BOOK_OPTIONS='-T -F0.97'
  # (or setenv PS2BOOK_OPTIONS '-T -F0.97')

You can also use this variable instead of PS2BOOK_PRINTER for specifying a
printer.

Will not work with embedded whitespace in options, i.e.
PS2BOOK_OPTIONS='--output="my file.ps"' will fail, how ever much you try
to quote the space.

=item B<PAPERCONF>

=item B<PAPERSIZE>

=item B<LC_PAPER>

See Section L<PAPER SIZE>.

=back


=head1 FILES

=over 4

=item B</etc/papersize>

See Section L</PAPER SIZE>.

=back

=head1 AUTHOR

Wolfgang Dobler  <Wolfgang [.] Dobler [at] kis.uni-freiburg.de>


=head1 SEE ALSO

pstops(1), psbook(1)


=head1 PROBLEMS

B<ps2book> reads in the whole file (plus the uncompressed version, if the
file is gzipped) and may use a lot of memory.
Bad if your printer has more memory than your computer.


=head1 BUGS

There can be no bugs in this program.
By definition.
Any problems are due to bad usage.

Please report any such cases of bad usage and I will try to fix them.

=cut

#  LocalWords:  ps PostScript psbook pstops bhnqtv ff outfile gzipped Duggan gv
#  LocalWords:  stdin ghostview fillfactor BoundingBox PageBoundingBox nocookie
