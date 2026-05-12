#import "common.typ": render-doc

#let render(meta, body) = {
  let merged = meta + (category: "brochure")
  render-doc(merged, body)
}
