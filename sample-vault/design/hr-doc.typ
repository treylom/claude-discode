#import "common.typ": render-doc

#let render(meta, body) = {
  let merged = meta + (category: "hr-doc")
  render-doc(merged, body)
}
