## Build boot.asm into a floppy

````commandline
$boot = [System.IO.File]::ReadAllBytes("build/boot.bin") // set the var for bootloader
$kern = [IO.File]::ReadAllBytes("build/kernel.bin")      // set var for kernel  
$img  = New-Object byte[] (1474560)                      // set the img to a 14.MB
[Array]::Copy($boot, 0, $img, 0, $boot.Length)           // copy the bootloader into the image  
[Array]::Copy($kern, 0, $img, 512, $kern.Length)         // copy the kernel at offset 512
[System.IO.File]::WriteAllBytes("build/floppy.img", $img)// now write the data
````
## Run

```commandline
qemu-system-x86_64 -fda build/floppy.img
```
