\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{russb}
              [1995/11/07 v1.2
 Class til russangboeger]
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{ssprep}}
\ProcessOptions
\LoadClass[a5paper,danish,twoside,9pt]{ssprep}
\RequirePackage{multicol,makeidx}
%\RequirePackage[lucidasmallscale]{lucidabr}
\usepackage{times}\renewcommand\sfdefault{pun}
\def\baselinestretch{.98}%
%---
\DeclareFontFamily{U}{notes}{}
\DeclareFontShape{U}{notes}{m}{n}
{ <6> <7> <8> <9> <10> <10.95> musicn11%
  <12> <14.4> musicn13%
  <17.28> musicn16%
  <20.74> <24.88> <29.86> <35.83> <40> musicn20 }{}
\def\music{\usefont{U}{notes}{m}{n}}
%----- Layout
\setlength{\textwidth}{12.45cm}
\setlength{\oddsidemargin}{-1in}
\addtolength{\oddsidemargin}{1cm}
\setlength{\evensidemargin}{-1in}
\addtolength{\evensidemargin}{1.4cm}
\setlength{\textheight}{18cm}
\setlength{\footskip}{0pt}
\setlength{\topmargin}{-1in}
\addtolength{\topmargin}{0cm}
\setlength{\headheight}{1.5cm}
\setlength{\headsep}{0cm}
\setcounter{secnumdepth}{0}
\def\becifstyle{\normalfont\small\sffamily}
\def\omkvstyle{\normalfont}%
\errorcontextlines=100
{\catcode`\p=12\catcode`\t=12
\gdef\@dblbas#1pt\gukke{\def\buk{#1}}}
\def\doublebaselinest{%
        \@scratchii=\baselinestretch pt
        \@scratchii=1.7\@scratchii\relax
        \expandafter\@dblbas\the\@scratchii\gukke\edef\baselinestretch{\buk}}
%--
\def\ps@rsb{%
    \renewcommand{\thepage}{\arabic{page}}
    \renewcommand{\@oddhead}{}%
    \renewcommand{\@evenhead}{}%
    \renewcommand{\@oddfoot}{%
        \hbox to \textwidth{\hfill\bfseries\sffamily\large\rlap{\smash{\quad\thepage}}}}%
    \renewcommand{\@evenfoot}{%
        \hbox to \textwidth{\sffamily\bfseries\large\llap{\smash{\thepage\quad}}\hfill}}%
}
\pagestyle{rsb}
%--
\def\@defchar#1{%                         % Definerer en karakter til et
   \bgroup                                % eller andet.
      \uccode`\~\expandafter`\csname\string#1\endcsname%
      \uppercase{%                        % Definitionen træder i kraft
   \egroup                                % når karakteren bliver aktiv
      \def~%                              %
   }%
}
\newcounter{verscnt}
\newcounter{sangcnt}\setcounter{sangcnt}{-1}

\def\@sangtitel#1#2{%
    \begingroup\raggedright\interlinepenalty=10000
    \parfillskip=0pt plus 1fill
    \Large\bfseries\sffamily
    \settowidth\hangindent{\thesangcnt.\hspace{.5em}}%
    $\thesangcnt$.\hspace{.5em}#1
    \nobreak\quad\nobreak
    \hfill
    \penalty550\hskip0pt plus -2fill
    \nobreak\hskip\hangindent\hbox{}\nobreak\hfill
    \nobreak\hskip-\hangindent
    \hbox{\normalfont\normalsize\itshape #2}\par\endgroup}
\def\@fulberthack#1{%
              \def\@tempa{Fulbert og Beatrice}
              \def\@tempb{#1}
              \ifx\@tempa\@tempb
                  \setcounter{page}{10}
              \fi}
\def\sang#1#2{\par\addvspace{1.4\baselineskip}%
              \addpenalty{-300}%
              \stepcounter{sangcnt}
              \index{#1}%
              \setcounter{verscnt}{-1}%
              \@lastversdoublefalse
              \@fulberthack{#1}
              \@sangtitel{#1}{#2}%
              \nobreak\addvspace{1.4\baselineskip}\@afterindentfalse\@afterheading}
\newlength\@endversskip
\newif\if@omkv
\newif\if@bro
\newif\if@lastversdouble
\newif\if@thisversdouble
\def\vers{\par\addpenalty{-1000}\addvspace{0pt}%
          \stepcounter{verscnt}\@omkvfalse\@ifnextchar[\@overs\@donvers}
\def\omkvaed{\par\addpenalty{-1000}\addvspace{0pt}\itshape\@omkvtrue
             \@ifnextchar[\@overs\@donvers}

\def\bro{\par\addpenalty{-1000}\addvspace{0pt}%
				 \@brotrue\@ifnextchar[\@overs\@donvers}
				
\def\@donvers{\@thisversdoublefalse
              \setlength\@endversskip{\baselineskip}%
              \addvspace{\@endversskip}%
              \if@omkv{\noindent\omkvstyle Omkv\ae d:\par\nobreak}\fi%
				  \if@bro{\noindent\omkvstyle Bridge:\par\nobreak}\fi%
              \if@lastversdouble\@nvers{10000}\else\@nvers{20}\fi}%
\newif\if@bc
\newif\if@tk
\newif\if@nvn
\def\@overs[#1#2]
    {\@bcfalse\@tkfalse\@nvnfalse
     \ifx#1b\@bctrue\fi
     \ifx#1t\@tktrue\fi
     \ifx#1n\@nvntrue\fi
     \ifx#2b\@bctrue\fi
     \ifx#2n\@nvntrue\fi
     \ifx#2t\@tktrue\fi
%     \ifx#3b\@bctrue\fi
%     \ifx#3t\@tktrue\fi
%     \ifx#3n\@vnvtrue\fi
     \if@tk
        \setlength\@endversskip{1.25\baselineskip}%
     \else
        \if@lastversdouble
           \setlength\@endversskip{1.25\baselineskip}%
        \else
           \setlength\@endversskip{1\baselineskip}%
        \fi
     \fi
     \addvspace\@endversskip
		\if@bro
        	\if@tk
        	\else
           	{\noindent\omkvstyle Bridge:\par\nobreak}
        	\fi%
     \fi
     \if@omkv
        \if@tk
        \else
           {\noindent\omkvstyle Omkv\ae d:\par\nobreak}
        \fi%
     \fi

     \setlength\@scratchi{.8\baselineskip}%
     \expandafter\@bcengine\expandafter{\the\@scratchi}%
     \lineskiplimit=0pt\lineskip=0pt
     \if@bc
       \if@tk
         \@btvers
       \else
         \@bvers
       \fi
     \else
       \if@tk
         \ClassWarning{russb}{[t] medfoerer [b]}
         \@btvers
       \else
         \@nvers{20}%
       \fi
     \fi}
\def\@nvers#1{%
   \bgroup                                % eller andet.
      \uccode`\~`\^^M%
      \uppercase{%                        % Definitionen træder i kraft
   \egroup                                % når karakteren bliver aktiv
      \def~{\par\penalty#1\hangafter=1\hangindent=1.5em\noindent\ignorespaces}%
                }%
   \catcode`\^^M=\active\@xnvers
}
\def\@xnvers{\clubpenalty=10000\widowpenalty=10000\interlinepenalty=10000
             \par\raggedright\advance\leftskip1.5em\noindent\mbox{}%
             \llap{%
               \hbox to 1.5em{%
                  \if@omkv\hss\else
						\if@bro\hss\else
                     \if@nvn\hss\else
                       \ifnum\c@verscnt<10
                          \theverscnt.\hfill%
                       \else
                          \addtocounter{verscnt}{-10}%
                          \llap{1}\theverscnt.\hfill%
                          \addtocounter{verscnt}{10}%
                       \fi
                     \fi
							\fi
                  \fi}}%
             \hangafter=1\hangindent=1.5em%
             \ignorespaces}
\def\asharp{\raise.6ex\hbox{\ensuremath{\sharp}}}%
\def\aflat{\raise.6ex\hbox{\ensuremath{\flat}}}%
\def\@bcengine#1{%
    \def\@starbc##1*##2>{%
         \smash{\raise#1\hbox{\rlap{\becifstyle ##1}}}%
         \setbox0\hbox{\becifstyle ##1}%
         \hbox to \wd0{##2\hfill}\egroup}%
    \def\@nostarbc##1>{\smash{\raise#1\hbox{\rlap{\becifstyle ##1}}}\egroup}%
    \catcode`\<=\active
    \@defchar<{\leavevmode
        \bgroup
% The \b and \x defined on the next line is the desired one - but dvips
% really really _really_ does not like it...
           \def\b{\aflat}%
           \def\x{\asharp}%
%          \def\b{\raise.7ex\hbox{\ensuremath{\m@th\flat}}}%
%          \def\b{{\music\large\smash{\raise1.1ex\hbox{\char'062}}}}%
%          \def\x{{\music\raise1.8ex\hbox{\char'064}}}%
%          \def\x{\raise.4ex\hbox{\kern.05em\#\kern-.05em}}%
          \def\+{$\m@th{}^+$}%
          \@ifstar\@starbc\@nostarbc}}
\newlength\@scratchi
\newlength\@scratchii
\def\@bvers{%
%    \spaceskip=.3em%
%    \xspaceskip=.3em%
    \doublebaselinest\selectfont%
    \@thisversdoubletrue
    \@nvers{10000}}
\newif\if@startbt\@startbtfalse
\def\@btvers{%
    \doublebaselinest\selectfont%
    \@startbttrue\@thisversdoublefalse
    \parindent=0pt\linepenalty=10000\hyphenpenalty=-9999
    \parfillskip=1.5em plus .9\textwidth\def\\{par}
    \spaceskip=.5em plus .25cm\xspaceskip=.5em plus .25cm%
    \@defchar|{%
        \if@startbt\@startbtfalse\else\unskip\penalty10000\hspace{.7em}\fi%
        \discretionary{\vrule width.4pt height.8\baselineskip depth.1\baselineskip}%
                      {\vrule width.4pt height.8\baselineskip depth.1\baselineskip}%
                      {\vrule width.4pt height.8\baselineskip depth.1\baselineskip}%
        \penalty10000\hspace{.7em}\ignorespaces
              }%
    \@defchar_{\ {}}%
    \catcode`\|=\active\catcode`\_=\active
    \if@omkv{\omkvstyle Omkv\ae d:\qquad}\fi\ignorespaces}%
\def\endvers{\if@thisversdouble\global\@lastversdoubletrue
             \else\global\@lastversdoublefalse\fi
             \@startbtfalse\unskip\par\addvspace\@endversskip
             \aftergroup\ignorespaces}
\let\endomkvaed\endvers
\def\meter#1#2{{%
\normalfont\bfseries\baselineskip=0pt\leavevmode\hbox{\vbox{\hbox{#1}\hbox{#2}}}%
}}
\def\allabreve{{\music\LARGE\char"52}}
%\def\meterC{{\music\LARGE\char"53}}
\def\@helpause{\raise.6ex\vbox to 2pt{%
         \hrule height.2pt depth0pt%
         \hbox to 5.25pt{\hfil\vrule height 1pt width 3pt depth0pt\hfil}%
         \vfil}}%
\def\@halvpause{\raise.6ex\vbox to 2pt{%
         \vfil%
         \hbox to 5.25pt{\hfil\vrule height 1pt width 3pt depth 0pt\hfil}%
         \hrule height.2pt depth0pt}}%
\def\p#1{%
   \if#14%
     {\music\leavevmode\lower1ex\hbox{>}}%
   \else
     \if#18%
       {\music\leavevmode\lower1ex\hbox{?}}%
     \else
       \if#12%
         \@halvpause
       \else
         \if#11%
            \@helpause
         \fi
       \fi
     \fi
   \fi}
\def\p#1{\ignorespaces}
\def\allabreve{\meter22}
\def\meterC{\meter44}
%\setlength\multicolsep{2ex\@plus.5ex}
\setlength\multicolsep{0pt}
\setcounter{finalcolumnbadness}{4000}
\def\sloppycols{\setcounter{columnbadness}{10001}\aftergroup\fussycols}
\def\fussycols{\setcounter{columnbadness}{0}}
\parskip=0pt\raggedbottom
%% 25/4-2004 har Rasmus Villemoes udkommenteret de næste par linjer og
%% erstattet dem med de efterfølgende lignende linjer. Forskellen
%% skulle gerne blive, at der også kommer sidetal med i index'et.

%\def\@wrindex#1{%
%  \protected@write\@indexfile{}%
%     {\string\indexentry{#1}{\thesangcnt}}%
%\endgroup
%\@esphack}

\def\sidetalswrap#1{%
  (\textbf{s. #1})}

%\def\@wrindex#1{%
%  \protected@write\@indexfile{}%
%  {\string\indexentry{#1, $\thesangcnt$|sidetalswrap}{\thepage}}%
%  \endgroup
%  \@esphack}

\def\@wrindex#1{%
  \protected@write\@indexfile{}%
  {\string\indexentry{#1|sidetalswrap}{\thepage}}%
  \endgroup
  \@esphack}

\renewenvironment{theindex}
    {\let\item\@idxitem
     {\Large\bfseries\sffamily\noindent Indholdsfortegnelse\par}%
     %% Den næste linje er ligeledes indsat 25/4-04 for at der kommer en
     %% forklaring med
%     {\vspace{\baselineskip}\noindent Tallene i (\textbf{parentes}) angiver sidetal.\par}%
     \begingroup\setlength\multicolsep{1.25\baselineskip}%
     \sloppycols\begin{multicols}{2}%
       \raggedright
    }{\end{multicols}\endgroup}%
\def\indexspace{\par\penalty-300\vspace{\baselineskip}}

\errorcontextlines=100

\renewcommand\@idxitem{\penalty0\par\hangindent1.5em}%

\def\slutbem#1{\par{\normalfont\vskip1.25\baselineskip\hfill\itshape#1\par}}
\fussycols%
\newcommand\spal[1]{\begin{multicols}{#1}}
\newcommand\laps{\end{multicols}}
\def\repon{\ensuremath{\|{\colon}}~\ignorespaces}
\def\repoff{\unskip~\ensuremath{{\colon}\|}}
\makeindex
\endinput
