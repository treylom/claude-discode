#let nf-cyan = rgb("#0EA5E9")
#let base-fonts = ("Pretendard", "Noto Sans CJK KR", "Apple SD Gothic Neo", "AppleGothic", "Arial Unicode MS", "Arial")
#let mono-fonts = ("JetBrains Mono", "Sarasa Mono K", "Noto Sans Mono CJK KR", "D2Coding", "Menlo", "Courier")

#let render-doc(meta, body) = {
  set document(title: meta.title, author: meta.company)
  set page(
    "a4",
    margin: (top: 22mm, bottom: 21mm, left: 19mm, right: 19mm),
    header: align(right)[#text(size: 8pt, fill: gray)[#meta.company · #meta.date]],
    footer: align(center)[#text(size: 8pt, fill: gray)[#context counter(page).display("1")]],
  )
  set text(font: base-fonts, lang: "ko", size: 10.4pt)
  set par(justify: true, leading: 0.65em)
  show heading.where(level: 1): it => block(below: 11pt)[
    #text(size: 20pt, weight: "bold", fill: nf-cyan)[#it.body]
  ]
  show heading.where(level: 2): it => block(above: 8pt, below: 5pt)[
    #text(size: 13pt, weight: "bold")[#it.body]
  ]
  show raw: set text(font: mono-fonts, size: 9pt)
  align(left)[
    = #meta.title
    #text(size: 9pt, fill: gray)[문서 유형: #meta.category · 기준일: #meta.date · 브랜드 컬러: \#0EA5E9]
    #line(length: 100%, stroke: nf-cyan + 0.8pt)
    #body
  ]
}
