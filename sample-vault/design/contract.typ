#import "common.typ": render-doc

#let render(meta, body) = {
  let merged = meta + (category: "contract")
  render-doc(merged, body)
}
