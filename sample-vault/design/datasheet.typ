#import "common.typ": render-doc

#let render(meta, body) = {
  let merged = meta + (category: "datasheet")
  render-doc(merged, body)
}
