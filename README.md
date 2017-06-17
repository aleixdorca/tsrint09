# tsrint09

Programa que detecta la polsació de la tecla F3 i escriu la comanda dir<cr> al buffer de teclat.

## Compilar i enllaçar:

Per compilar fa falta masm32 i link16:

c:\>ml /c KBSwitch.asm  
c:\>link16 KBSwitch.obj;  
c:\>KBSwitch.exe

NOTA: El programa funciona en Win7. No cal la instal·lació de DOSBox, FreeDOS, o similars.
