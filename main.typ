#import "template.typ": *

#show: songbook.with(
  title: "F-Klubbens Fabelagtige Sangbog",
)

//#set block(stroke: 2pt + red)

#forside

#fritfor

#indholdfortegnelse(cols: 2, block_height: 80%)

#v(1cm)
#align(center)[
  #image("assets/foret.png", width: 100%)
]
#pagebreak()

#kapitelside(titel: "F-Klub Sange")

#pagebreak()

// Gammel forside (ikke en forside her)
#place(
  center + bottom,
  dx: 0cm,
  dy: 0cm,
  image("assets/fklub-sange-forside.png", width: 70%),
)

// Futlandia
#include "sange/futlandia.typ"

#pagebreak()

// En målrettet vise
#include "sange/målrettetvise.typ"

#pagebreak()

// Tegning af Rudin
#align(center + horizon)[
  #image("assets/rudin.png", width: 70%)
]

#pagebreak()

// En introduktionsvise
#include "sange/introduktionsvise.typ"

// Masser af cc
#include "sange/masserafcc.typ"

#pagebreak()

// Mat'matik (Bubbi Bjørn)
#include "sange/matematik.typ"

// Fytteturssangen
#include "sange/fytteturssangen.typ"

#pagebreak()

// Havd skal vi kode i nat
#include "sange/hvadskalvikodeinat.typ"

#pagebreak()

// En kort en lang (billedsangen)
#include "sange/enkortenlang.typ"

#pagebreak()

// Livet (im a lumberjack and I'm okay)
#include "sange/livet.typ"

// Hvem sidder foran skærmen
#include "sange/hvemsidderforanskærmen.typ"

#pagebreak()

// Franskbrød billede
#place(
  center,
  dx: 0cm,
  dy: 3.25cm,
  image("assets/franskbrod.png", width: 8cm),
)

// Fredagsfranskbrød
#include "sange/brødsangen.typ"

#v(3cm)

// Vi er ikek humanister
#include "sange/vierikkehumanister.typ"
#pagebreak()

// C compiler
#include "sange/dumåfåminccompilernårjegdør.typ"

#place(
  right,
  dx: 0cm,
  dy: -4cm,
  image("assets/amiga.png", width: 5cm),
)

// Danskens sande glæade (tal/mad sangen)
#include "sange/danskernessaneglæde.typ"
#pagebreak()


// En meget nostalgisk vise
#include "sange/enmegetnostalgiskvise.typ"
#pagebreak()


// Tegning af Sofa Fra F-nüt
#align(center + horizon)[
  #image("assets/fnut-sofa.png", width: 110%)
]

#pagebreak()

// Regn-sangen (42)
#include "sange/regnsangen.typ"

// Lilel grønen frø
#include "sange/denlillegrønnefrø.typ"

// Kampsangen
#include "sange/dat62.typ"

#pagebreak()

#place(
  center + bottom,
  dx: 0cm,
  dy: 0cm,
  image("assets/øre.png", width: 7cm),
)

// Jeg en nørd (Pokémon)
#include "sange/jegerennørd.typ"

#pagebreak()

// På Cassiopeia til Foobar
#include "sange/påcassiopeiatilfoobar.typ"

// Fit er Frit (bella chao)
#include "sange/fiterfrit.typ"

#pagebreak()

// Alle DAT'er er emget glade for Mini
// Kontekts: Der var requestet at den ikke var med
// Indtil at en sang kan være på plads 21, er den redacted
#context[
  #highlight(fill:black, top-edge: "bounds", bottom-edge: "bounds")[
  #include "sange/miniblirbortført.typ"
  ]
]

#v(-1em)
// Veteranens nostalgiske vise (nyere version af FVJ variaent)
#include "sange/veteranensnostalgiskesang.typ"

#pagebreak()


// Halvejs kylling
#place(
  right + bottom,
  dx: 0cm,
  dy: 0cm,
  image("assets/halvejs.png", width: 5cm),
)


// Hvorfor skal vi hejse et flag
#include "sange/flagsang.typ"

#pagebreak()

// CLRS
#include "sange/clrs.typ"

// Drunken BoAnd
#include "sange/drunkenboand.typ"


#pagebreak()

// Tegning af eksamens-angst
#align(center + horizon)[
  #image("assets/eksamens-angst.png", width: 90%)
]

#pagebreak()

// F-Luciasangen på normal
#include "sange/luciasangenikkeonsdag.typ"

// F-Luciasangen på onsdag
#include "sange/luciasangenfredagsfranskbrød.typ"

// Alle Dat'er er galde for poster
#include "sange/alledatererfladeforporter.typ"

#pagebreak()

// Kvindelig eksaminstor
#place(
  right + horizon,
  dx: .5cm,
  dy: 0cm,
  image("assets/eksaminator.png", width: 6cm),
)

// Eksaminandernes kort
#include "sange/eksaminanderneskor.typ"

// Meyers vise
#include "sange/meyersvise.typ"

#pagebreak()

// BoAnd Krabebsangen
#include "sange/krabbeboand.typ"

#include "sange/vierpåvejstrandvej.typ"


#pagebreak()

#place(
  center + bottom,
  dx: 0cm,
  dy: 1cm,
  image("assets/eksamen.png", width: 100%),
)

// Et sidte farvel
#include "sange/etsidstefarvel.typ"

#pagebreak()

// Resultater af klubbens afgangsprøve
#include "sange/resultateraffklubbensafgangsprøve.typ"

#pagebreak()

// Bingospillren
#include "sange/bingospilleren.typ"

// Fottesangen
#include "sange/fottesangen.typ"

#place(
  bottom + right,
  dx: 0cm,
  dy: 0cm,
  image("assets/fotte.png", width: 5cm),
)

#pagebreak()

// Der kan man C
#include "sange/derkanmanc.typ"

// F-nüt 1985 f-klub-sangkonkurence - vindersangen
#include "sange/fnut1985vindersangen.typ"

//#pagebreak() // disablede hele siden, da sangene nok ikke kommer til at blive sunget
// F-nüt 1985 f-klub-sangkonkurence - hold 1
//#include "sange/fnut1985rossethold1.typ"
// F-nüt 1985 f-klub-sangkonkurence - hold 2
//#include "sange/fnut1985rossethold2.typ"
// F-nüt 1985 f-klub-sangkonkurence - hold 3
//#include "sange/fnut1985rossethold3.typ"

#nynummerpræfiks("F")

#kapitelside(titel: [Sange fra verden \ #text(size: .8em)[og om lejerbålet]], asset: "assets/verden.png", spacing: 1cm)

#include "sange/unsorted/costadelsol.typ"

#include "sange/unsorted/hjemmebrænderiet.typ"

#pagebreak()

// Vendelbomanden
#place(
  bottom + right,
  dx: 0cm,
  dy: .25cm,
  image("assets/vendelbo.png", width: 5.5cm),
)

#include "sange/unsorted/vendelboensfestsang.typ"

#pagebreak()

#include "sange/unsorted/frujensenfratolne.typ"

#pagebreak()

#include "sange/unsorted/dervarenskikkeligbondemand.typ"

// #align(center)[#image("assets/eps2png/bondemand.png", width: 12cm)]

#pagebreak()

#place(
  horizon + right,
  dx: .5cm,
  dy: -1.5cm,
  image("assets/nobeer.png", width: 10cm),
)

#include "sange/specielle/langtfrahjemmeudenøl.typ"

#v(4.7cm)

#include "sange/specielle/dereretølrigtland.typ"

#pagebreak()

#include "sange/unsorted/himmelhunden.typ"

#include "sange/unsorted/viharlejrbålher.typ"

#pagebreak()

#include "sange/unsorted/derernogetgaltidanmark.typ"

#include "sange/specielle/forureningsvisen.typ"

#pagebreak()

#include "sange/unsorted/sevenedigogdø.typ"

#include "sange/unsorted/ienlillebåddergynder.typ"

#pagebreak()

#include "sange/unsorted/hvalenhvalborg.typ"

#align(center)[
  // #image("assets/eps2png/calvinandhobbes.png", width: 80%)
]

#include "sange/unsorted/joanna.typ"

#pagebreak()

#include "sange/tågekammeret/tågekamemret-feaster-2025.typ"

#pagebreak()

#include "sange/tågekammeret/tågekamemret-bestpåtur.typ"

#nynummerpræfiks("J")

#kapitelside(titel: "Julesange", asset: "assets/julemand.png", spacing: 1cm)

#place(
  bottom + center,
  dx: 0cm,
  dy: 1cm,
  image("assets/julemad.png", width: 5.5cm),
)

#include "sange/etbarnerfødtibethlehem.typ"

#include "sange/julemadogdrikke.typ"

#pagebreak()

#include "sange/unsorted/påloftetsiddernissenmedsinjulegrød.typ"

#include "sange/unsorted/julebalinisseland.typ"

#pagebreak()

#include "sange/specielle/jegsåjulemandenkyssemor.typ"

#include "sange/unsorted/sørenbanjomus.typ"




//#kapitelside(titel: "Lejerbålsange", asset: "assets/eps2png/lejrbaal.png")
//
//#include "sange/unsorted/kringsattaffiender.typ"
//#pagebreak()
//#include "sange/unsorted/svantenslykkeligedag.typ"
//#include "sange/unsorted/denrødetråd.typ"
//#pagebreak()
//
//#include "sange/unsorted/allesømændergladeforpiger.typ"
//#pagebreak()
//
//#include "sange/unsorted/mcarine.typ"
//#include "sange/unsorted/bubbibjørn.typ"
//#include "sange/unsorted/puffdenmagiskedrage.typ"
//#pagebreak()
//#include "sange/unsorted/buster.typ"



// K sektion
#nynummerpræfiks("K")

// #kapitelside(titel: "Grå Sange", asset: "assets/eps2png/sex.png")
#pagebreak()

#include "sange/unsorted/enmandfaldtnedfraførstesal.typ"
#pagebreak()
#include "sange/unsorted/lilleprinsesse.typ"
