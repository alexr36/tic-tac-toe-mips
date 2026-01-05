# Tic Tac Toe - MIPS Assembly

A classic Tic Tac Toe game implemented in MIPS assembly language with player vs. computer gameplay, multiple rounds, and score tracking.

## Features

- Player vs Computer gameplay
- Multi-round mode (1-5 rounds)
- Automatic win detection
- Score tracking across rounds
- Input validation
- Audio feedback (MIDI support required)

## How to Run

1. Open MARS or QtSpim simulator
2. Load `tictactoe.asm`
3. Assemble and run
4. Follow on-screen prompts

## How to Play

- **Player symbol**: O
- **Computer symbol**: X
- **Board positions**: 1-9 (like a numpad)
- Enter a number (1-9) when it's your turn
- Get three in a row to win - just like in real tic-tac-toe

```
1|2|3
4|5|6
7|8|9
```

## Technical Details

### Key Implementation Features
- **Board**: 9-byte array (0=empty, 1=player, 2=computer)
- **Computer AI**: Simple first-available position strategy
- **Win detection**: Checks 8 conditions (3 rows, 3 columns, 2 diagonals)
- **Register usage**: `$s0-$s7` for game state, `$t0-$t9` for temporary values

### Requirements
- MARS 4.5+ or QtSpim
- Standard MIPS syscalls
- Optional MIDI support for sound effects
