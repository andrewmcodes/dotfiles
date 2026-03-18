# ANSI color reference

Use this quick reference to preview ANSI foreground and background color codes in a shell.

## Foreground colors

| Code | Color | Example command |
| ---: | --- | --- |
| 39 | Default foreground color | `echo -e "Default \e[39mDefault"` |
| 30 | Black | `echo -e "Default \e[30mBlack"` |
| 31 | Red | `echo -e "Default \e[31mRed"` |
| 32 | Green | `echo -e "Default \e[32mGreen"` |
| 33 | Yellow | `echo -e "Default \e[33mYellow"` |
| 34 | Blue | `echo -e "Default \e[34mBlue"` |
| 35 | Magenta | `echo -e "Default \e[35mMagenta"` |
| 36 | Cyan | `echo -e "Default \e[36mCyan"` |
| 37 | Light gray | `echo -e "Default \e[37mLight gray"` |
| 90 | Dark gray | `echo -e "Default \e[90mDark gray"` |
| 91 | Light red | `echo -e "Default \e[91mLight red"` |
| 92 | Light green | `echo -e "Default \e[92mLight green"` |
| 93 | Light yellow | `echo -e "Default \e[93mLight yellow"` |
| 94 | Light blue | `echo -e "Default \e[94mLight blue"` |
| 95 | Light magenta | `echo -e "Default \e[95mLight magenta"` |
| 96 | Light cyan | `echo -e "Default \e[96mLight cyan"` |
| 97 | White | `echo -e "Default \e[97mWhite"` |

## Background colors

| Code | Color | Example command |
| ---: | --- | --- |
| 49 | Default background color | `echo -e "Default \e[49mDefault"` |
| 40 | Black | `echo -e "Default \e[40mBlack"` |
| 41 | Red | `echo -e "Default \e[41mRed"` |
| 42 | Green | `echo -e "Default \e[42mGreen"` |
| 43 | Yellow | `echo -e "Default \e[43mYellow"` |
| 44 | Blue | `echo -e "Default \e[44mBlue"` |
| 45 | Magenta | `echo -e "Default \e[45mMagenta"` |
| 46 | Cyan | `echo -e "Default \e[46mCyan"` |
| 47 | Light gray | `echo -e "Default \e[47mLight gray"` |
| 100 | Dark gray | `echo -e "Default \e[100mDark gray"` |
| 101 | Light red | `echo -e "Default \e[101mLight red"` |
| 102 | Light green | `echo -e "Default \e[102mLight green"` |
| 103 | Light yellow | `echo -e "Default \e[103mLight yellow"` |
| 104 | Light blue | `echo -e "Default \e[104mLight blue"` |
| 105 | Light magenta | `echo -e "Default \e[105mLight magenta"` |
| 106 | Light cyan | `echo -e "Default \e[106mLight cyan"` |
| 107 | White | `echo -e "Default \e[107mWhite"` |

## Useful regex

To delete all lines that start with a number, use:

```regex
^\d.*\n?
```
