#import "common.typ": render-doc

#let render(meta, body) = {
  let merged = meta + (category: "meeting-quarterly")
  render-doc(merged, body)
}
