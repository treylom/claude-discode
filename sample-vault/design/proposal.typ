#import "common.typ": render-doc

#let render(meta, body) = {
  let merged = meta + (category: "proposal")
  render-doc(merged, body)
}
