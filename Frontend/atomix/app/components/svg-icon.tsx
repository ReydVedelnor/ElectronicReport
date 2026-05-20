import type { CSSProperties, HTMLAttributes } from "react";

type SvgIconProps = HTMLAttributes<HTMLSpanElement> & {
  name: string;
  width?: number | string;
  height?: number | string;
  size?: number | string;
  alt?: string;
};

export function SvgIcon({
  name,
  width,
  height,
  size,
  alt,
  className = "",
  style,
  ...props
}: SvgIconProps) {
  const resolvedWidth = width ?? size;
  const resolvedHeight = height ?? size;

  const iconStyle: CSSProperties = {
    ...(style ?? {}),
    ...(resolvedWidth !== undefined ? { width: resolvedWidth } : {}),
    ...(resolvedHeight !== undefined ? { height: resolvedHeight } : {}),
    WebkitMaskImage: `url(/icons/${name}.svg)`,
    maskImage: `url(/icons/${name}.svg)`,
  };

  const classes = ["svg-icon", className].filter(Boolean).join(" ");

  return (
    <span
      role={alt ? "img" : undefined}
      aria-label={alt || undefined}
      aria-hidden={alt ? undefined : true}
      className={classes}
      style={iconStyle}
      {...props}
    />
  );
}
