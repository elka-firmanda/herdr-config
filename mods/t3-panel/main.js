// The Changes panel's toggle, in T3's tab bar: on when the right panel shows, click or ctrl-shift-g to collapse it.
import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { theme, run, layout, shared, nextCommand } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

function toggle() {
  const panel = find(layout(), "panel");
  if (!panel) return;
  run(panel.hidden ? "layout.show" : "layout.hide", { id: "panel" });
}

export default class PanelToggle extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      for (;;) if (await nextCommand() === "toggle") toggle();
    });
  }

  render() {
    const t = theme(), on = !find(layout(), "panel")?.hidden, compact = shared("bar.compact");
    return h_flex().size_full().items_center().justify_end().pr(4)
      .child(div().id("panel-toggle").h(28).px(8).flex_none().flex().items_center().rounded(8)
        .bg(on ? t.selected : t.chrome).text_color(on ? t.foreground : t.muted)
        .hover(s => s.bg(t.hover))
        .role("button").accessibility_label(on ? "Collapse changes panel" : "Show changes panel")
        .tooltip("Changes")
        .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
        .on_click(() => toggle())
        .child(svg("mods/changes/changes.svg").size(16).flex_none())
        .when(!compact, el => el.child(div().pl(6).text_size(12).child("Changes"))));
  }
}
