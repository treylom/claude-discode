#import "common.typ": render-doc

#let render(meta, body) = {
  let merged = meta + (category: "report-annual")
  render-doc(merged, body)
}
