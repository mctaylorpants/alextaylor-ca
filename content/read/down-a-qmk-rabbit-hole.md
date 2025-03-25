---
title: Down a QMK rabbit hole
kind: article
created_at: 2025-03-24
---

Today I went down a fun rabbit hole of [QMK](https://qmk.fm/), the open-source firmware for mechanical keyboards (and other input devices). Like the start of any good rabbit hole, it all started with an extremely specific mission: fixing a minor nit with my new keyboard.

## TAPPING too fast
I bought a [NuPhy Air75 V2](https://nuphy.com/collections/keyboards/products/air75-v2) to try out a low-profile mechanical keyboard (it's also nice that it's wireless!).

I started using [VIA Configurator](https://caniusevia.com/) to remap keys. In particular, I wanted to try a home-row arrow setup which would let me use the vim-style mapping of h, j, k, and l as &larr;, &uarr;, &darr;, and &rarr;. Since I still obviously want to use those keys for their intended alphabetical purpose, a modifier key was in order. Hey, Caps Lock is on the home row too, and I already remap it to Esc... why not modify it even further so that holding down Caps Lock triggers another layer?

After a few trips to Google and Claude, I got the mapping code I wanted:

```
LT(7, KC_ESC)
```

I used the `LT` ("layer tap") function to activate layer 7 when held, or Esc when tapped. From there, it was a simple matter to remap h, j, k and l to the arrow keys on layer 7. Perfect!

... and then I tried using it.

As it turns out, when I use arrow keys, I use them quickly. I'm often tapping up on the command-line or in the address bar to navigate history. Using the layer-tap, I found it wasn't responding quickly enough and I'd end up sending "k" instead of "up" unless I held down Caps Lock for a (admittedly minuscule, but nevertheless infuriating) moment.

More trips to the search gods led me to a tantalizing solution: a config setting named "[Hold On Other Key Press](https://docs.qmk.fm/tap_hold#hold-on-other-key-press)". From the docs:

> This mode makes tap and hold keys (like Layer Tap) work better for fast typists

It me! Problem solved. Except, this option is _not_ configurable through VIA Configurator: it's a lower-level configuration that needs to be set in the firmware itself.

Enter my QMK rabbit hole.

## Down we go...

As far as rabbit holes go, this ended up being a shallow one. QMK's toolchain is really nice, and pleasant to work with. I ran through [the tutorial](https://docs.qmk.fm/newbs_getting_started) and found my way to Reddit when I realized that NuPhy's QMK support is not particularly straightforward.

Here's what I ended up doing:

**Set up QMK with NuPhy's custom branch.** I found [a helpful Reddit post](https://www.reddit.com/r/NuPhy/comments/1dsve0c/compiling_qmk_for_nuphy_keyboards_spoiler_alert/) on how to do this, since NuPhy's keyboards haven't made their way into the main QMK repo yet - they've got their own fork.

```
qmk setup nuphy-src/qmk_firmware -b nuphy-keyboards
```

Mercifully, I had none of the compile issues mentioned in the thread!

**Take the compiler for a spin.** As suggested in the Reddit post, I tried compiling the keymap built for VIA Configurator:

```
qmk compile -kb nuphy/air75_v2/ansi -km via
```

This generated a `.bin` file, which I could use to...

**Flash the firmware.** I used [QMK Toolbox](https://qmk.fm/toolbox) to load the `.bin` file and flash the firmware on to my keyboard (which involved holding down Esc when you plug it in to boot the keyboard into flashing mode).

## New firmware, who dis?

After poking around with various configuration files, I got myself oriented:

- `keyboards/nuphy/air75_v2/ansi` is the root folder of the firmware I'm working with; it's full of C files that configure the keyboard itself, and what ends up compiling down to the `.bin` file.
- Within this folder, `config.h` contains a bunch of - unsurprisingly - config directives. Here I added one line: **`#define HOLD_ON_OTHER_KEY_PRESS`**, which is the whole reason I went on this journey in the first place!
- There's a `keymaps` folder where you can store various mappings of the keys themselves. I suppose this is more "user-facing" so it's kept separate from the lower-level config of the keyboard. I know you can define your own custom keymap, but I didn't touch anything in here because I want to keep using VIA Configurator while I'm playing around layout.
- Finally, I have a `json` file I exported from VIA Configurator's web UI after I set up my key mappings. This is _not_ the same format as QMK's JSON format ([like this one provided by NuPhy for use in VIA](https://github.com/nuphy-src/qmk_firmware/blob/nuphy-keyboards/keyboards/nuphy/air75_v2/ansi/keymaps/via/NuPhy%20Air75%20V2%20via3.json)), which was confusing to me at first. For VIA, I think the QMK JSON file is used to load in the keyboard definition, and the exportable JSON file is just used for saving the updated key mapping.

Eventually once I'm reasonably happy with the layout, I could conceivably compile it directly into the default keymap. But for now, this toolchain works nicely!

And the best part: now my arrow-taps are lightning fast! ⚡️

