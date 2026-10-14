"""Generate original vector creatures and short synthesized effects. No external art."""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / "assets"


def creature(name, color, shapes):
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320" width="320" height="320">
    <defs>
      <radialGradient id="glow"><stop stop-color="{color}" stop-opacity=".21"/><stop offset="1" stop-color="{color}" stop-opacity="0"/></radialGradient>
      <linearGradient id="body" x1="0" y1="0" x2=".7" y2="1"><stop stop-color="{color}"/><stop offset="1" stop-color="#384344"/></linearGradient>
    </defs>
    <circle cx="160" cy="167" r="153" fill="url(#glow)"/>
    <circle cx="160" cy="164" r="115" fill="none" stroke="{color}" stroke-opacity=".2"/>
    <path d="M160 29v12M160 287v12M25 164h12M283 164h12" stroke="{color}" stroke-opacity=".6"/>
    <ellipse cx="160" cy="266" rx="74" ry="10" fill="#000" opacity=".22"/>
    {shapes}
    <path d="M64 223l4-9 4 9-4 9zM254 89l3-7 3 7-3 7zM229 250l3-6 3 6-3 6z" fill="{color}" opacity=".8"/>
    </svg>'''
    (ROOT / f"{name}.svg").write_text(svg)


creature("ember", "#ef987b", '''
<path d="M199 235Q286 219 268 133Q253 174 218 169Q270 114 241 71Q236 126 193 147" fill="#b46450"/>
<path d="M212 220Q262 196 254 167Q245 187 213 185" fill="#f6c8a4"/>
<path d="M111 186Q91 247 129 258L182 258Q224 240 202 182" fill="url(#body)"/>
<path d="M107 136L89 56L140 98M180 99L231 56L213 139" fill="#ef987b" stroke="#f3bb97" stroke-width="3"/>
<path d="M105 80L112 119L133 107M217 80L190 107L209 119" fill="#674448"/>
<path d="M103 125Q160 87 217 125L226 166L185 210L160 224L135 210L94 166Z" fill="url(#body)"/>
<path d="M101 157L139 179L160 214L181 179L220 157L185 209L160 224L134 209Z" fill="#f9dab2"/>
<path d="M119 150l20 7M181 157l20-7" stroke="#19262b" stroke-width="7" stroke-linecap="round"/>
<path d="M152 184h16l-8 9z" fill="#253235"/>
<path d="M151 130l9-24 9 24-9 12z" fill="#f9d5a3"/>
<path d="M130 253l5-24M181 253l-5-24" stroke="#f9dab2" stroke-width="10" stroke-linecap="round"/>
''')
creature("moss", "#91c8a1", '''
<path d="M103 145Q56 129 70 79Q106 80 127 124M187 118Q203 62 250 76Q248 124 212 145" fill="#689878"/>
<path d="M85 88l28 44M235 85l-33 49" stroke="#c5e1b0" stroke-width="3"/>
<path d="M98 172Q91 247 123 260L195 260Q228 242 218 169" fill="url(#body)"/>
<path d="M88 145Q92 108 128 106L194 106Q231 111 233 151L219 193Q160 224 101 193Z" fill="url(#body)"/>
<path d="M115 157l20 3M185 160l20-3" stroke="#203b33" stroke-width="7" stroke-linecap="round"/>
<path d="M151 181h18l-9 8z" fill="#29493b"/>
<path d="M123 206L139 233L178 233L196 206" fill="#c7d5a0"/>
<path d="M123 112Q119 78 146 68Q162 89 147 109M149 107Q156 54 193 58Q197 94 172 111" fill="#b8d690"/>
<path d="M129 250v-17M190 250v-17" stroke="#bfd9aa" stroke-width="12" stroke-linecap="round"/>
<circle cx="113" cy="180" r="4" fill="#f5d58c"/><circle cx="209" cy="180" r="4" fill="#f5d58c"/>
''')
creature("volt", "#e8cf81", '''
<path d="M107 166L48 113L67 175L109 221M212 162L271 112L254 179L213 221" fill="#ad9871"/>
<path d="M107 170L71 145L91 191M213 170L251 145L230 191" fill="#e8cf81"/>
<path d="M119 181Q100 246 160 260Q219 245 202 180" fill="url(#body)"/>
<path d="M111 112L113 76L151 102L177 76L210 107L220 167L185 201L134 201L99 167Z" fill="url(#body)"/>
<path d="M123 136L142 153L121 168M198 136L179 153L200 168" fill="#f9ecc0"/>
<path d="M128 150l10 3M183 153l10-3" stroke="#353337" stroke-width="7" stroke-linecap="round"/>
<path d="M150 170h20l-10 19z" fill="#f6ac71"/>
<path d="M153 118l13-34h-9l17-31-4 35h10l-18 30z" fill="#fff0b9"/>
<path d="M145 215l12 15-9 12 21-9-10-14 13-10" fill="#fff0b9"/>
''')
creature("spore", "#b4c1a3", '''
<path d="M123 180Q104 249 139 259L182 259Q219 236 192 179" fill="#b7b7a1"/>
<path d="M72 161Q74 82 161 81Q249 83 249 161Q162 204 72 161Z" fill="url(#body)" stroke="#c9d2b5" stroke-width="2"/>
<path d="M85 159Q160 177 235 159" fill="none" stroke="#e4dfc2" stroke-width="6"/>
<circle cx="129" cy="120" r="12" fill="#d6d6b9"/><circle cx="185" cy="109" r="9" fill="#d6d6b9"/><circle cx="217" cy="142" r="7" fill="#d6d6b9"/>
<path d="M137 211v9M180 211v9" stroke="#344342" stroke-width="7" stroke-linecap="round"/>
<path d="M151 237q8 7 16 0" fill="none" stroke="#344342" stroke-width="3"/>
''')
creature("owl", "#b9a0d5", '''
<path d="M111 171L61 223L100 237M207 171L264 222L221 237" fill="#79698f"/>
<path d="M103 131L93 62L146 109M179 109L231 62L218 134" fill="#a18bbd"/>
<path d="M104 136Q94 257 160 269Q227 257 216 136" fill="url(#body)"/>
<path d="M111 141L150 126L160 153L170 126L210 141L199 184L166 191L160 169L154 191L122 184Z" fill="#ddd1df"/>
<path d="M126 153l19 8M175 161l19-8" stroke="#393047" stroke-width="8" stroke-linecap="round"/>
<path d="M153 180h14l-7 17z" fill="#e8bc86"/>
<path d="M137 215l23 13 23-13M144 238l16 9 16-9" fill="none" stroke="#cec0da" stroke-width="3"/>
''')
creature("stag", "#bea4db", '''
<path d="M121 141L82 98L75 45M92 113L49 101L34 68M80 77L49 47M197 141L239 98L247 45M229 112L273 101L289 68M242 76L273 47" fill="none" stroke="#c9b6e4" stroke-width="10" stroke-linecap="round"/>
<path d="M103 147L65 127L82 165L118 173M212 146L253 127L237 167L203 176" fill="#8b78a8"/>
<path d="M117 139L200 139L212 196L187 241L160 267L133 241L106 196Z" fill="url(#body)" stroke="#d4c0e6" stroke-width="2"/>
<path d="M160 142v92M129 193l16 7M177 200l16-7" stroke="#eee1ef" stroke-width="5" stroke-linecap="round"/>
<path d="M146 234h28l-14 15z" fill="#342c44"/>
<path d="M160 68l11 20-11 20-11-20z" fill="#edcc8f"/>
<circle cx="160" cy="88" r="26" fill="none" stroke="#edcc8f" stroke-opacity=".6"/>
''')

for name, notes, duration in [("play", [220, 330, 440], .2), ("reward", [440, 554, 659], .42), ("select", [660], .065)]:
    sample_rate = 22050
    samples = []
    for i in range(int(duration * sample_rate)):
        t = i / sample_rate
        envelope = (1 - t / duration) ** 2
        value = sum(math.sin(2 * math.pi * note * t) for note in notes) / len(notes)
        samples.append(struct.pack("<h", int(value * envelope * 5500)))
    with wave.open(str(ROOT / f"{name}.wav"), "wb") as out:
        out.setparams((1, 2, sample_rate, 0, "NONE", "not compressed"))
        out.writeframes(b"".join(samples))
creature("ignivar", "#ffc48c", '''
<path d="M196 237Q294 212 274 105Q263 164 218 168Q281 100 240 43Q249 109 199 125" fill="#b75f48"/>
<path d="M217 221Q278 188 262 140Q254 184 219 185" fill="#ffce90"/>
<path d="M111 190Q96 253 128 267H192Q223 250 209 185" fill="url(#body)"/>
<path d="M99 133L78 36L140 96M180 96L244 35L221 136" fill="#ffc48c" stroke="#ffe5b0" stroke-width="4"/>
<path d="M103 68L116 118L136 104M221 68L188 104L211 118" fill="#965447"/>
<path d="M93 131L137 105H186L230 133L238 173L192 222L160 245L127 222L83 173Z" fill="url(#body)"/>
<path d="M89 165L132 184L160 230L188 184L232 165L196 221L160 245L125 221Z" fill="#fff0cf"/>
<path d="M117 155l22 8M181 163l22-8" stroke="#573833" stroke-width="8" stroke-linecap="round"/>
<path d="M150 194h20l-10 13z" fill="#513a39"/>
<path d="M145 132l15-45 15 45-15 17z" fill="#fff0b9"/>
<path d="M117 259l12-28M202 259l-12-28" stroke="#fff0cf" stroke-width="13" stroke-linecap="round"/>
<path d="M130 66l8-23 11 21M175 65l10-22 9 22" fill="#ffdb9c"/>
''')
creature("verdalio", "#c0dea2", '''
<path d="M98 136Q41 96 64 57Q103 62 129 105M187 110Q208 46 263 59Q254 111 216 141" fill="#88a776"/>
<path d="M91 172Q68 248 112 268H209Q250 235 222 168" fill="url(#body)"/>
<path d="M83 134Q85 95 131 94H193Q241 102 240 148L224 199L196 224H124L91 195Z" fill="url(#body)" stroke="#e4e8b7" stroke-width="3"/>
<path d="M116 150l21 5M186 155l21-5" stroke="#334e3a" stroke-width="8" stroke-linecap="round"/>
<path d="M148 180h24l-12 13z" fill="#405d3e"/>
<path d="M117 219L139 249H183L209 219" fill="#ebebc2"/>
<path d="M119 100Q94 62 119 42Q148 46 148 83M150 95Q153 32 199 36Q218 65 181 105" fill="#d5e8a5"/>
<path d="M69 114L44 137L74 151M250 114l30 23-32 13" fill="#d5e8a5"/>
<circle cx="123" cy="183" r="6" fill="#ffdc98"/><circle cx="200" cy="183" r="6" fill="#ffdc98"/>
<path d="M119 260l7-24M205 260l-7-24" stroke="#ebebc2" stroke-width="13" stroke-linecap="round"/>
''')
creature("tempestral", "#f4dc92", '''
<path d="M111 165L25 90L46 174L102 226M207 165L295 90L272 175L216 226" fill="#aa9879"/>
<path d="M108 166L44 115L60 167L95 198M212 166l65-51-18 53-31 31" fill="#f4dc92"/>
<path d="M112 188Q89 253 160 273Q232 253 206 183" fill="url(#body)"/>
<path d="M103 103L98 48L149 91L180 48L215 101L232 157L195 217H126L88 157Z" fill="url(#body)" stroke="#ffe9b1" stroke-width="3"/>
<path d="M109 127L143 152L118 174M211 127l-33 25 24 22" fill="#fff4cf"/>
<path d="M122 149l15 5M185 154l15-5" stroke="#4d443b" stroke-width="8" stroke-linecap="round"/>
<path d="M147 179h26l-13 25z" fill="#e99868"/>
<path d="M146 117l14-48h-10l26-41-10 52h11l-16 36z" fill="#fff5c9"/>
<path d="M142 225l17 15-12 19 28-18-16-17 18-12" fill="#fff4cf"/>
''')

(ROOT / "powers").mkdir(exist_ok=True)

def power_icon(name, color, shapes):
    (ROOT / "powers" / f"{name}.svg").write_text(f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">
    <defs><radialGradient id="g"><stop stop-color="{color}" stop-opacity=".25"/><stop offset="1" stop-color="{color}" stop-opacity="0"/></radialGradient></defs>
    <circle cx="64" cy="64" r="63" fill="url(#g)"/>
    <circle cx="64" cy="64" r="47" fill="none" stroke="{color}" stroke-opacity=".2"/>
    <g fill="{color}" stroke="{color}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">{shapes}</g>
    </svg>''')

power_icon("fireball", "#ef987b", '<path d="M25 98Q7 68 50 43Q58 35 54 18Q85 31 78 55Q88 49 93 33Q128 89 81 106Q52 119 25 98Z" stroke="none"/><path d="M40 94Q31 78 58 60Q67 54 64 43Q87 65 84 85Q84 102 63 105Z" fill="#ffe2ab" stroke="none"/>')
power_icon("claw", "#ef987b", '<path d="M23 99L53 25L47 76Z M48 108L78 20L74 79Z M75 106L101 28L99 84Z" stroke="none"/>')
power_icon("fire_guard", "#ef987b", '<path d="M27 34L64 20L101 34V64Q95 91 64 111Q32 91 27 64Z" fill="none" stroke-width="5"/><path d="M46 78Q40 56 60 47L63 34Q83 53 83 77Q80 92 64 94Q48 92 46 78Z" stroke="none"/>')
power_icon("thorns", "#91c8a1", '<path d="M24 106Q48 74 41 39Q70 19 103 37Q66 45 65 72Q66 92 43 110" fill="none" stroke-width="7"/><path d="M42 64L22 52L42 50M56 45L44 21L65 37M65 80l24-3-22 16" stroke="none"/>')
power_icon("roots", "#91c8a1", '<path d="M28 36L64 20L100 36V70Q89 92 64 109Q37 91 28 70Z" fill="none" stroke-width="5"/><path d="M64 35v60M64 57L43 44M64 72l21-21M64 79L45 88M64 85l17 7" fill="none" stroke-width="5"/>')
power_icon("seed", "#91c8a1", '<path d="M64 104V60" fill="none" stroke-width="6"/><path d="M63 68Q20 73 23 32Q62 28 63 68Z M65 59Q67 21 108 21Q104 62 65 59Z" stroke="none"/><path d="M44 114h40" stroke-width="5"/>')
power_icon("lightning", "#e8cf81", '<path d="M71 10L28 75H57L44 120L106 49H73L87 10Z" stroke="none"/><path d="M17 30l13 7M105 91l10 8" fill="none"/>')
power_icon("storm_guard", "#e8cf81", '<path d="M28 34L64 19L100 34V70Q88 96 64 110Q39 96 28 70Z" fill="none" stroke-width="5"/><path d="M71 33L47 73H64L58 97L85 56H67Z" stroke="none"/>')
power_icon("dive", "#e8cf81", '<path d="M22 24L57 53L90 23L75 59L110 56L63 101L15 61L49 65Z" stroke="none"/><path d="M63 98v20M91 87l13 13M28 88l-12 12" fill="none" stroke-width="4"/>')
power_icon("inferno", "#ffc48c", '<circle cx="64" cy="64" r="29" fill="#ffe9b1" stroke="none"/><path d="M64 9v16M64 104v16M9 64h16M104 64h16M25 25l12 12M92 92l12 12M24 104l13-13M92 37l12-12" fill="none" stroke-width="6"/><path d="M51 70l13-26 13 26-13 13z" fill="#d97d54" stroke="none"/>')
power_icon("sanctuary", "#c0dea2", '<path d="M23 112V56L64 22L105 56V112Z" fill="none" stroke-width="5"/><path d="M64 106V63M64 83Q31 76 41 49Q65 53 64 83M65 73Q64 45 91 41Q99 70 65 73" stroke="none"/><path d="M17 115h94" fill="none" stroke-width="5"/>')
power_icon("judgment", "#f4dc92", '<circle cx="64" cy="64" r="42" fill="none" stroke-width="5"/><path d="M69 28L43 72H60L54 106L86 58H67Z" stroke="none"/><path d="M64 4v11M64 113v11M4 64h11M113 64h11" fill="none" stroke-width="4"/>')
print("Generated 9 creature forms, 12 power illustrations and 3 original synthesized effects.")
