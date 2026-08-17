# BasicRotationBehavior

A `Behavior` specialization for angle-valued properties whose animation
travels along the nearest equivalent angle rather than a straight-line
interpolation.

`BasicRotationBehavior` is meant for angle-semantic properties such as
`rotation`, where values are equivalent modulo 360°. When the target
property changes, the animation does not interpolate directly from the
current value to the target; instead it picks the equivalent angle closest
to the current value as the animation target. For example, going from 270°
to 0° actually animates 270°→360° (a clockwise 90° swing), then snaps the
property back to the true target 0° — visually a no-op snap that avoids a
large counterclockwise 270° rotation.

If the target changes again mid-animation, the animation continues from the
current intermediate angle along the nearest path (no jump). The host usage
is identical to `BasicNumberBehavior`:

```qml
Item {
    property int direction: Qore.E
    rotation: direction === Qore.E ? 225 : 0
    BasicRotationBehavior on rotation {
        enabled: root.Style.animationEnabled
        duration: root.Style.movementDuration
    }
}
```

> **Note:** Only use this for angle-semantic properties (values equivalent
> modulo 360°). Applied to an ordinary numeric property it normalizes the
> target into the ±180° neighborhood of the start, producing wrong behavior.

## Properties

- `duration : real` (alias to the internal `NumberAnimation.duration`)
  Animation duration in milliseconds. Default `Style.transitionDuration`.

- `easing : group` (alias to the internal `NumberAnimation.easing`)
  Easing curve. Default `Easing.InOutQuad`. The `easing.type` sub-property
  holds the curve enumeration.

- `enabled : bool`
  Animation toggle. Defaults to `targetProperty.object?.Style.animationEnabled
  ?? Style.animationEnabled` — the target object's `Style.animationEnabled`
  when available, otherwise the ambient `Style.animationEnabled`. The host
  may override this binding.

Inherited from `Behavior` (Qt Quick Templates): `targetProperty`,
`targetValue`, `targetValueChanged`, `enabled`. See the Qt documentation for
the inherited members.

## Signals

This type defines no additional signals. It inherits
`Behavior.targetValueChanged` (emitted whenever a property change is
intercepted).

## Methods

This type defines no additional methods. It inherits the members of
`Behavior`.

## Usage Example

`BasicRotationBehavior` is a reusable `Behavior`; attach it to any
angle-valued property as shown in the overview example. It is not a
standalone visual component.
