**THIS PAGE IS A WORK IN PROGRESS**

This style guide is designed to give you an overview of the precepts and specific element styles used to create GUIs. The contents of this guide are merely suggestions, and are not to be taken as gospel. Usage of the word "must" means a _very strong recommendation_, but things _may_ be changed according to the individual circumstances.

This style guide assumes you know how to create GUIs, assign styles to elements, and edit styles. If you do not know these things, this guide won't be of much use to you.

This guide makes use of styles provided by flib. See [gui-styles](gui-styles.md.html) for a full list of included styles.

## Window

![](https://raw.githubusercontent.com/factoriolib/flib/master/docs/assets/gui-style-guide/window-types.png)

> The different window types.

Standalone windows are created using the default frame style. Because of this, you need not specify a style when creating the element.

For windows that contain multiple sub-windows (e.g. most windows that hold a character inventory) `outer_frame` is used as the outer frame and `inner_frame_in_outer_frame` is used for each internal window.

Generally there are three kinds of windows:

- **Standard** windows:
  - **Must** have a close button in the top-right corner.
  - **Must** be opened as a result of clicking a button or using a hotkey.
- **Dialog** windows:
  - **Must** have a row of dialog buttons across the bottom.
  - **Must not** have a close button.
  - **Must** be opened as a result of a hierarchal action - you go "back" to the previous action, or you "confirm" the current action.
  - **Must** have a "Back" button in the bottom-left corner
  - **May** have a "Confirm" button in the bottom-right corner
    - Should only be omitted if there are multiple possible "confirmation" actions (i.e. the main menu can open many possible sub-windows).
  - **May** have other buttons on the dialog row, though these should be used sparingly (use [tool buttons](#Tool-button) instead).
- **mod_gui** windows:
  - **Must** be placed in the `mod_gui.frame_flow` GUI parent.
  - **Must** use the `mod_gui.frame_style` style.
  - **Must not** have a close button _or_ a dialog row.
  - **Must** be opened using a button in the `mod_gui.button_flow`, or by using a hotkey.

There are not the only kinds of windows that can exist - is also a type that I like to call a **compact** window. These windows do not have any set rules, are are either persistent on the screen or are opened/closed due to some other user action (i.e. when holding a specific item). As is their namesake, they are usually compact and unobtrusive.

### Titlebar

![](https://raw.githubusercontent.com/factoriolib/flib/master/docs/assets/gui-style-guide/dialog-types.png)

> Draggable vs. non-draggable windows.

Each non-compact window **must** have a titlebar. All titlebars **must** have a _title_, and for windows that are meant to be draggable, the titlebar **must** include a drag handle. **Standard** windows also include a close button. Other frame action buttons may be added to the left of the close button or to the left of the title, but should be used sparingly.

If you are creating a **dialog window**, you do not need to create a custom titlebar - you can simply set `caption` and `use_header_filler` on the frame itself, and it'll automatically work.

However, if you are creating a **standard window**, follow these guidelines:

- **Titlebar flow:**
  - A `horizontal_flow` with the default style.
  - For draggable windows, set this element's `drag_target` to the window frame.
- **Title text:**
  - A `label` that uses the `frame_title` style.
  - Only capitalize the first word in the title - all other words should be lowercase.
    - Exceptions can be made for mod names.
  - Set `ignored_by_interaction` to `true` to facilitate dragging.
- **Drag handle (for draggable windows):**
  - An `empty-widget` set to the `draggable_space_header` style.
    - `height` set to 24
    - `horizontally_stretchable` set to `true`
    - `right_margin` set to `4`.
  - Set `ignored_by_interaction` to `true` to facilitate dragging.
- **Pusher (for non-draggable windows):**

  - An `empty-widget` with `horizontally_stretchable` set to `true`, or using the `flib_horizontal_pusher` style.

- **Frame action buttons:**
  - A `sprite-button` set to the `frame_action_button` style.
  - Default sprite:
    - A 29x29 image with 3px of padding around the edges (32x32 file size).
    - Colored `rgb(227, 227, 227)`.
    - Close buttons use `utility/close_white` for this.
  - Hovered and clicked sprites:
    - A 29x29 image with 3px of padding around the edges (32x32 file size).
    - Colored `rgb(29, 29, 29)`.
    - Close buttons use `utility/close_black` for this.

### Content frame

![](https://raw.githubusercontent.com/factoriolib/flib/master/docs/assets/gui-style-guide/content-frame-with-padding.png)

> An example of `inside_shallow_frame_with_padding`, demonstrating the built-in 12px padding.

Each non-compact window **must** have at least one "content frame" (the light grey pane seen in the above screenshots). This is where the meat of your interface will go.

Content frames are created using the `inside_shallow_frame_with_padding` style. This will give you 12px of padding in the frame. If you need to have zero padding (i.e. for adding a scroll pane or a toolbar), use `inside_shallow_frame` instead.

It is good practice to separate different "purposes" in a GUI with different content panes:

![](https://raw.githubusercontent.com/factoriolib/flib/master/docs/assets/gui-style-guide/content-frame-separation.png)

> Separating content panes by "purpose". The left pane is dedicated to search functionality, and the right is dedicated to displaying the object information. These "purposes" are consistent throughout usage of the mod.

If you add multiple content panes, add them to a flow element with `horizontal_spacing` or `vertical_spacing` set to `12`.

### Dialog row

The dialog row is the row of buttons at the bottom of a dialog window. Generally, a window will have one or two of these, but more can be added if necessary.

The game uses a left-to-right methodology for its navigation. Therefore, the leftmost dialog button is the "back" or "cancel" action, while the rightmost is the "confirm" action. Because dialogs have an actual "confirm" action, changes to the content of the dialog should not be saved until the "confirm" button is clicked and the window closed.

## Toolbar

Toolbars are a great place to keep a content pane's "title" as well as tools used in that pane. You can see two examples of toolbars in the Recipe Book screenshot above.

Toolbars are created using the `subheader_frame` style. There are a few locations where they are acceptable:

- At the top of an `inside_shallow_frame` (no padding)
- At the top of an `inside_deep_frame` (usually above a tabbed pane)
- Below the tab row in a tabbed pane. To use a toolbar here, the tabbed pane must use `tabbed_pane_with_no_side_padding` and the toolbar `subheader_frame_with_top_border`.
