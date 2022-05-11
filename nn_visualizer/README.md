resource: https://tgmstat.wordpress.com/2013/06/12/draw-neural-network-diagrams-graphviz/

# instructions:

Once you have the description code into file.txt, you then type

```
dot -Tpng -O file.txt

^that "O" is a capital O
```

on the command-line to produce a .PNG image. You can use -Tpdf to produce a .pdf file or -Tformat if you want another available format. dot is the default tool to draw “hierarchical” or layered drawings of directed graphs.
