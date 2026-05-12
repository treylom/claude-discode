#import "common.typ": render-doc

#let render(meta, body) = {
  let merged = meta + (category: "marketing")
  render-doc(merged, body)
}
