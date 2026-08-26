import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/widgets.dart';

class BrandLogo extends StatelessWidget {
  final double width;
  const BrandLogo({super.key, this.width = 228});
  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_logoSvg, width: width);
  }
}

class TableSceneIllustration extends StatelessWidget {
  final double width;
  const TableSceneIllustration({super.key, this.width = 270});
  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(_tableSvg, width: width);
}

class YelledSceneIllustration extends StatelessWidget {
  final double width;
  const YelledSceneIllustration({super.key, this.width = 250});
  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(_yelledSvg, width: width);
}

const _logoSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="228" height="150" viewBox="0 0 200 140">
<g stroke="#211A12" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" fill="none">
  <path d="M29 110 V126 M39 110 V126"/>
  <rect x="23" y="64" width="22" height="46" rx="11" fill="#FF5A3C"/>
  <path d="M34 66 Q43 59 47 57"/>
  <circle cx="49" cy="48" r="11" fill="#FF5A3C"/>
  <path d="M75 108 V124 M85 108 V124"/>
  <rect x="69" y="62" width="22" height="46" rx="11" fill="#7A5CC4"/>
  <path d="M80 64 Q86 57 89 55"/>
  <circle cx="90" cy="46" r="11" fill="#7A5CC4"/>
  <path d="M121 106 V122 M131 106 V122"/>
  <rect x="115" y="60" width="22" height="46" rx="11" fill="#2E7D6B"/>
  <path d="M126 62 Q129 55 129 51"/>
  <circle cx="129" cy="42" r="11" fill="#2E7D6B"/>
  <path d="M167 104 V120 M177 104 V120"/>
  <rect x="161" y="58" width="22" height="46" rx="11" fill="#FFB020"/>
  <path d="M172 60 V51"/>
  <circle cx="172" cy="42" r="11" fill="#FFB020"/>
</g>
<g stroke="#FF5A3C" stroke-width="3.5" stroke-linecap="round" fill="none">
  <path d="M172 24 V16"/><path d="M158 30 l-5 -6"/><path d="M186 30 l5 -6"/>
</g>
</svg>''';

const _tableSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="270" height="240" viewBox="0 0 270 240">
<circle cx="215" cy="46" r="28" fill="#FFB020" stroke="#211A12" stroke-width="4"/>
<rect x="34" y="150" width="202" height="20" rx="6" fill="#E7B77E" stroke="#211A12" stroke-width="4"/>
<g stroke="#211A12" stroke-width="4">
  <rect x="52" y="170" width="12" height="46" rx="4" fill="#D89E5C"/>
  <rect x="206" y="170" width="12" height="46" rx="4" fill="#D89E5C"/>
</g>
<g stroke="#211A12" stroke-width="4">
  <circle cx="70" cy="120" r="20" fill="#FF5A3C"/>
  <rect x="56" y="138" width="28" height="30" rx="12" fill="#FF5A3C" transform="rotate(14 70 150)"/>
</g>
<g stroke="#211A12" stroke-width="4">
  <circle cx="135" cy="112" r="21" fill="#2E7D6B"/>
  <rect x="120" y="130" width="30" height="34" rx="13" fill="#2E7D6B" transform="rotate(-10 135 145)"/>
</g>
<g stroke="#211A12" stroke-width="4">
  <circle cx="200" cy="122" r="20" fill="#7A5CC4"/>
  <rect x="186" y="139" width="28" height="30" rx="12" fill="#7A5CC4" transform="rotate(12 200 150)"/>
</g>
</svg>''';

const _yelledSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="250" height="230" viewBox="0 0 250 230">
<g stroke="#211A12" stroke-width="4">
  <circle cx="52" cy="150" r="20" fill="#FF5A3C"/>
  <rect x="42" y="168" width="20" height="42" rx="9" fill="#FF5A3C"/>
</g>
<g stroke="#211A12" stroke-width="4">
  <circle cx="105" cy="146" r="21" fill="#2E7D6B"/>
  <rect x="94" y="165" width="22" height="46" rx="10" fill="#2E7D6B"/>
</g>
<g stroke="#211A12" stroke-width="4">
  <circle cx="160" cy="150" r="20" fill="#7A5CC4"/>
  <rect x="150" y="168" width="20" height="42" rx="9" fill="#7A5CC4"/>
</g>
<g stroke="#211A12" stroke-width="4">
  <circle cx="210" cy="147" r="21" fill="#C98A2E"/>
  <rect x="199" y="166" width="22" height="44" rx="10" fill="#C98A2E"/>
</g>
<g stroke="#FFB020" stroke-width="4" stroke-linecap="round" fill="none">
  <path d="M40 118l-6-12"/><path d="M125 108l0-14"/><path d="M222 118l7-12"/>
</g>
</svg>''';
