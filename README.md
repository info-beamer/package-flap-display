# A software flap display

This is a [flap display](https://en.wikipedia.org/wiki/Split-flap_display) you can run on
your info-beamer hosted devices. You can easily update the text by editing the setup and
hitting save.

[![Import](https://cdn.infobeamer.com/s/img/import.png)](https://info-beamer.com/use?url=https://github.com/info-beamer/package-flap-display.git)

## Automatically updating content

Alternatively you can also automatically update the content with a
[package service](https://info-beamer.com/doc/package-services). In the
source code of this package you'll find an example package service in
the file [service.example](https://github.com/info-beamer/package-flap-display/blob/master/service.example).
If you fork the [package code](https://github.com/info-beamer/package-flap-display), rename this file
to `service` in your fork so info-beamer recognizes it as a package service.

The code for updating the sign output automatically is quite small. Here
is a minimal example that output 'Hello World' and the current unix
timestamp in the first three lines of your display:

```python
#!/usr/bin/python
import time
from ibquery import InfoBeamerQuery

while 1:
    ib = InfoBeamerQuery("127.0.0.1")
    con = ib.node("display/atomic").io(raw=True)
    con.write("Hello\nWorld\n%d\n" % time.time())
    con.close()

    time.sleep(1)
```

See the annotated source code for more information on how
updating exactly works.

You must send your data encoded as utf8. The following
letters are supported by the classic mode:

```
 abcdefghijklmnopqrstuvwxyzäöü0123456789@#-.,:?!()
```

## Updating from outside

Instead of running a package service you can also modify
the output from outside by having an external program
directly connecting to the info-beamer process on the
device. You'll have to
[enable access](https://info-beamer.com/doc/device-configuration#exposeinfobeamerports)
for that. Note that there is no authentication, so anyone
who can reach your info-beamer device can update
the output.

Once enabled, connect to the device with a TCP connection
on port 4444 and send the following data (line-breaks for
illustration purposes only):

```
*raw/display/atomic\n
Line1\n
Line2\n
```

If your TCP client disconnects, the sent lines will
become active on the screen.

## Adding your own style

Checkout https://github.com/opendatacity/splitflap, install the
dependencies, edit `config.js` with the charset, animation steps
and other details. Then go to `textures/` and run

```
nodejs 1_generate_letters.js
nodejs 2_raytrace.js
```

to generate `../images/texture_400.png`. Use the `refit.py`
tool included in this package to rearrange the texture so it
fits into 2048x2048 pixels. See the comment in `refit.py`
for how to run this. Finally add your style to `node.lua` and
`node.json`.
