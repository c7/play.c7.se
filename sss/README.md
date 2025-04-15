# SSS: Stone, Shears, Scroll 🪨✂️📜

_A minimalist, retro-inspired twist on the classic game._

## AI

### Prompt

> Please give me some suggestions for a minimalistic game with the theme "rock paper scissors"
>
> Must be playable on a machine with the following gardware Specs:
>
>     Display: 160x160 pixels, 4 customizable colors, updated at 60 Hz.
>     Memory: 64 KB linear RAM, memory-mapped I/O, save states.
>     Cartridge Size Limit: 64 KB.
>     Input: Keyboard, mouse, touchscreen, up to 4 gamepads.
>     Audio: 2 pulse wave channels, 1 triangle wave channel, 1 noise channel.
>     Disk Storage: 1024 bytes.

### Answer

**Rock Paper Scissors: Stone, Shears, Scroll**
_A minimalist, retro-inspired twist on the classic game._

#### Core Features

1. **Visual Style**
    - **160x160 Display**: Use geometric shapes _(circle = Rock, rectangle = Scroll/Paper, triangles = Shears/Scissors)_.
    - **4-Color Palette**:
        - `Color 1`: Background (dark gray).
        - `Color 2`: UI/text (white).
        - `Color 3`: Player highlight (cyan).
        - `Color 4`: Enemy highlight (red).
    - **Animations**: Smooth 60 Hz transitions _(e.g., choices "clashing" on win/loss)_.
2. **Game Modes**
    - **Classic Duel**: Best-of-3 against AI.
    - **Endless Mode**: Streak survival with escalating AI difficulty.
    - **2-Player Local**: Split-screen (80x160 each) with gamepad/keyboard support.
3. **Controls**
    - **Touch/Keyboard/Gamepad**: Three buttons for choices _(◯=Rock, ▯=Scroll, ✂=Shears)_.
    - **Quick Menus**: Navigate with directional inputs or mouse.
4. **AI Behavior**
    - **Adaptive Logic**: Tracks player patterns _(limited to 3 recent moves in RAM)_.
    - **Difficulty Tiers**:
        - **Easy**: Random choices.
        - **Hard**: Counters frequent picks _(e.g., if player uses Rock twice, AI picks Scroll)_.
5. **Audio**
    - **Pulse Waves**: Upbeat 8-bit jingle during menus.
    - **Triangle Wave**: Tense "countdown" before AI reveals choice.
    - **Noise Channel**: "Crunch" sound on win, "shatter" on loss.
6. **Storage**
    - **Save States**: Track win/loss ratios and highest streak (uses <1 KB).
    - **Cartridge Size**: Pixel art and audio fit in 64 KB (compressed sprites + low-fi SFX).

#### Technical Implementation

- **Assets**:
    - **Sprites**: 16x16 per choice _(3 total + animations = ~2 KB)_.
    - **Sound**: 4 tracks _(title, gameplay, win, loss) using 2 pulse channels + noise_.
- **Memory**:
    - **Game state**: 512 bytes (scores, AI logic, input).
    - **Save data**: 512 bytes (stats).

#### Example Play Session

1. **Title Screen**: Pulse-wave chiptune plays; press Start.
2. **Mode Select**: Choose "Endless Mode".
3. **Gameplay**:
    - Tap ✂ (Shears) on touchscreen.
    - AI reveals ▯ (Scroll) after triangle-wave "drumroll".
    - Shears cut Scroll → WIN (cyan flash + crunch SFX).
4. **Repeat**: Streak counter increments; AI adapts.

#### Why It Works

- Fits all hardware limits (tiny assets, minimal CPU load).
- Leverages 4 colors and audio channels for retro charm.
- Adds strategic depth with adaptive AI and modes.

## Technology

Using [Zig](https://ziglang.org/) to compile a `.wasm` cart
for use in [WASM-4](https://wasm4.org/)

## Development

File watcher can be started by calling:
```sh
zig build --watch
```

Running the cart in WASM-4:
```sh
zig build run
```

Deploy:
```
make deploy
```
