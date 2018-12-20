/*------------------------------------------------------------------------------

	"garlic_graf.c" : fase 2 / programador G

	Funciones de gesti�n de las ventanas de texto (gr�ficos), para GARLIC 2.0

------------------------------------------------------------------------------*/
#include <nds.h>

#include <garlic_system.h>	// definici�n de funciones y variables de sistema
#include <garlic_font.h>	// definici�n gr�fica de caracteres

/* definiciones para realizar c�lculos relativos a la posici�n de los caracteres
	dentro de las ventanas gr�ficas, que pueden ser 4 o 16 */
#define NVENT	16				// n�mero de ventanas totales
#define PPART	4				// n�mero de ventanas horizontales o verticales
								// (particiones de pantalla)
#define VCOLS	32				// columnas y filas de cualquier ventana
#define VFILS	24
#define PCOLS	VCOLS * PPART	// n�mero de columnas totales (en pantalla)
#define PFILS	VFILS * PPART	// n�mero de filas totales (en pantalla)


const unsigned int char_colors[] = {240, 96, 64};	// amarillo, verde, rojo

int fondo2, fondo3;				// Id's de los mapas de fondo 2 y fondo3
u16 *ptrMapa2;					// Puntero a la diecci�n inicial del mapa de fondo2
char pcActual[9];				// Variable para guardar la informaci�n de PCactual en la tabla de la pantalla inferior
char infoLiniaTabla[9];			// Variable para guardar la informaci�n de PID y Prog en la tabla de la pantalla inferior
const char espacioVacio4[] = "    ";   // Variable para borrar el contenido de los campos PID y Prog de a tabla de la pantalla inferior
const char espacioVacio9[] = "        ";   // Variable para borrar el contenido de los campos PID y Prog de a tabla de la pantalla inferior


/* _gg_generarMarco: dibuja el marco de la ventana que se indica por par�metro*/
void _gg_generarMarco(int v, int color)
{
	u16 * ptrMapa3 = bgGetMapPtr(fondo3); 		// Obtenemos la @ inicial del fondo 3 (su mapa)
	 
	ptrMapa3 += (v/PPART) * VFILS * PCOLS;		// @ inicial de la 1� ventana del comienzo de cada fila de ventanas
	ptrMapa3 += (v%PPART) * VCOLS;			// @inicial de las otras ventanas de cada fila
	
	// Marco arriba izquierda
	ptrMapa3[0] = 103 + color*128;
	// Marco arriba derecha
	ptrMapa3[VCOLS-1] = 102 + color*128;
	// Marco abajo izquierda
	ptrMapa3[(VFILS-1)*PCOLS] = 100 + color*128;
	// Marco abajo derecha
	ptrMapa3[(VFILS-1)*PCOLS+(VCOLS-1)] = 101 + color*128;
	
	// Marcos de los lados arriba y abajo
	for (int j = 1; j < VCOLS - 1; j++)
	{
		ptrMapa3[j] = 99 + color*128;
		ptrMapa3[(VFILS-1)*PCOLS+j] = 97+ color*128;
	}
	
	// Marcos de los lados izquierda y derecha
	for (int i = 1; i < VFILS - 1; i++)
	{
		ptrMapa3[i*PCOLS] = 96+ color*128;
		ptrMapa3[i*PCOLS+(VCOLS-1)] = 98+ color*128;
	} 
	
}


/* _gg_iniGraf: inicializa el procesador gr�fico A para GARLIC 1.0 */
void _gg_iniGrafA()
{
	videoSetMode(MODE_5_2D); /* Processador gr�fico principal inicialitzado */
	lcdMainOnTop();				// Salida en la pantalla principal superior de la NDS */
	vramSetBankA(VRAM_A_MAIN_BG_0x06000000); // Banco de mem�ria de video A reservado

	// Inicializar los fondos gr�ficos 2 y 3 en modo Extended Rotation, con tama�o de 512x512 p�xeles
	
	/* C�lculo del tama�o del mapa:
			num_baldosas = fondo de 1024x1024 p�xel / baldosa de 8x8 p�xel = 128x128 baldosas
			tama�o del mapa = num_baldosas * num Bytes/baldosa = 128x128 baldosas * 2 Bytes/baldosa = 2^7 * 2^7 * 2 = 2^15 Bytes = 32KB
		
	   C�lculo del tama�o de las baldosas:
			tama�o baldosas = num baldosas * num p�xeles/baldosa * num Byte/p�xel = 128 baldosas * 8x8 p�xel/baldosa * 1 Byte/p�xel =
							= 2^7 * 2^3 * 2^3 * 1 = 2*13 Bytes = 8 KBytes
			desplazamiento tileBase = 2 * tama�o mapa / 16KB = 2 * 8 KB / 16KB = 1
	*/
	// bgInit(int layer, BgType type, BgSize size, int mapBase *2k, int tileBase *16k)
	fondo2 = bgInit(2,BgType_ExRotation, BgSize_ER_1024x1024, 0,4);
	fondo3 = bgInit(3,BgType_ExRotation, BgSize_ER_1024x1024, 16,4);
	
	ptrMapa2 =  bgGetMapPtr(fondo2);

	
	// Fijar el fondo 3 como m�s prioritario que el fondo 2
	bgSetPriority(fondo3,2);
	bgSetPriority(fondo2,3);
	
	// Descomprimir el contenido de la fuente de letras
	// 		decompress(origen, destino, tipos);
	decompress(garlic_fontTiles, bgGetGfxPtr(fondo2), LZ77Vram);
	
	// Copiar la paleta de colores de la fuente de letras
	// 		dmaCopy(origen, destino, tama�o):
	dmaCopy(garlic_fontPal, BG_PALETTE, sizeof(garlic_fontPal));
	
	// Copiar tres veces las 128 baldosas b�sicas y cambiar sus colores:
	u16 * ptrBaldosas = bgGetGfxPtr(fondo2);
	for (int i = 0; i < 3; i++)  // 3 -> numero total de colores
	{
		
		// Cada vez que se accede a memoria VRAM se carga un halfword -> 
		// -> total baldosas / 2 Bytes = 8KB / 2B = 4 KB = 4096 accesos totales para recorrer los 128 baldosas.
		for (int j = 0; j < 4096; j++)
		{
			// Cada acceso, un halfword o bien es 0x00(�ndice al color negro) o 0xFF(�ndice al color blanco)
			if (ptrBaldosas[j] == 0x00FF)
				ptrBaldosas[(i+1)*4096 + j] = (u16) char_colors[i];
			else if (ptrBaldosas[j] == 0xFF00)
				ptrBaldosas[(i+1)*4096 + j] = (u16) char_colors[i] << 8;
			else if (ptrBaldosas[j] == 0xFFFF)
				ptrBaldosas[(i+1)*4096 + j] = ((u16) char_colors[i] << 8) + (u16) char_colors[i];
		}
	
	}
	
	// Generar los marcos de las ventanas de texto del fondo 3:
	for (int k = 0; k < NVENT; k++) 
		_gg_generarMarco(k,3);

	
	// Escalar los fondos 2 y 3 para que se ajusten a las dimensiones de la NDS (reducci�n del 50%)
	/*
	bgSetScale(int id, s32 x, s32 y)
	Tanto la x como y tiene el formato 24.8, es decir 24 bits para la parte entera y 8 bits para la parte fraccionaria.
	Como 50% del escalado es 0,5 = 1/2 => 2.00 => 0x200 => 512 [fase 1]
	0x400 => 1024 [fase 2]
	*/
	bgSetScale(fondo2,1024,1024);
	bgSetScale(fondo3,1024,1024);
	
	bgUpdate();
			
}



/* _gg_procesarFormato: copia los caracteres del string de formato sobre el
					  string resultante, pero identifica los c�digos de formato
					  precedidos por '%' e inserta la representaci�n ASCII de
					  los valores indicados por par�metro.
	Par�metros:
		formato	->	string con c�digos de formato (ver descripci�n _gg_escribir);
		val1, val2	->	valores a transcribir, sean n�mero de c�digo ASCII (%c),
					un n�mero natural (%d, %x) o un puntero a string (%s);
		resultado	->	mensaje resultante.
	Observaci�n:
		Se supone que el string resultante tiene reservado espacio de memoria
		suficiente para albergar todo el mensaje, incluyendo los caracteres
		literales del formato y la transcripci�n a c�digo ASCII de los valores.
*/
void _gg_procesarFormato(char *formato, unsigned int val1, unsigned int val2,
																char *resultado)
{
	
	int i, iRes, iTemp, numVal;
	char car;
	char temp[11];
	char * ptrStrTemp = (char *) 0;		// Puntero a string(%s)
	char noCeroEncont = 0;		// Variable booleana para poder escribir los 0's del final de n�mero hexadecimal.
	
	i = 0; 
	iRes = 0;
	numVal = 0;
	car = formato[i];
	
	while ((car != '\0') && (iRes < (VCOLS*3)))
	{
		// Si hay valores a transcribir:
		if (car == '%')
		{
			car = formato[++i];
			if (car == '%') 
			{
				resultado[iRes++] = car;
			}
			else if ((car == 'd') && (numVal < 2))
			{
				if (numVal == 0) 
					_gs_num2str_dec(temp, sizeof(temp), val1);
				else 
					_gs_num2str_dec(temp, sizeof(temp), val2);
				numVal++;
				
				iTemp = 0;
				while (temp[iTemp] != '\0')
				{	
					if (temp[iTemp] != ' ') 
						resultado[iRes++] = temp[iTemp]; // Sacar los espacios en blanco
					iTemp++;
				}
			}
			else if ((car == 'x') && (numVal < 2))
			{
				
				if (val1 == 0)
				{
					resultado[iRes++] = '0';
					numVal++;
				} 
				else if (val2 == 0)
				{
					resultado[iRes++] = '0';
					numVal++;
				}
				else
				{
					if (numVal == 0) 
						_gs_num2str_hex(temp, sizeof(temp), val1);
					else 
						_gs_num2str_hex(temp, sizeof(temp), val2);
					numVal++;
					
					iTemp = 0;
					while (temp[iTemp] != '\0')
					{	
						if ((temp[iTemp] != '0') || (noCeroEncont)) // Sacar los 0 de delante(la parte restante)
						{
							noCeroEncont = 1;
							resultado[iRes++] = temp[iTemp]; 
						}
						iTemp++;
					}
				}
			}
			else if ((car == 'c') && (numVal < 2))
			{
				if (numVal == 0) 
					resultado[iRes++] = (char) val1;
				else 
					resultado[iRes++] = (char) val2;
				numVal++;
			}
			else if ((car == 's') && (numVal < 2))
			{
				if (numVal == 0) 
					ptrStrTemp = (char *) val1;
				else 
					ptrStrTemp = (char *) val2;
				numVal++;
				
				iTemp = 0;
				while ( ptrStrTemp[iTemp] != '\0')
					resultado[iRes++] = ptrStrTemp[iTemp++];
				
			}
			else if ((car >= '0') && (car <= '3'))
			{
				resultado[iRes++] = '%';
				resultado[iRes++] = car;
			}
			else 
			{
				resultado[iRes++] = '%';
			}
			
		} 
		else  // No hay valores a transcribir
		{
			resultado[iRes++] = car;
		}
		car = formato[++i];
	}
	resultado[iRes] = '\0';
	
}



/* _gg_escribir: escribe una cadena de caracteres en la ventana indicada;
	Par�metros:
		formato	->	cadena de formato, terminada con centinela '\0';
					admite '\n' (salto de l�nea), '\t' (tabulador, 4 espacios)
					y c�digos entre 32 y 159 (los 32 �ltimos son caracteres
					gr�ficos), adem�s de c�digos de formato %c, %d, %x y %s
					(max. 2 c�digos por cadena)
		val1	->	valor a sustituir en primer c�digo de formato, si existe
		val2	->	valor a sustituir en segundo c�digo de formato, si existe
					- los valores pueden ser un c�digo ASCII (%c), un valor
					  natural de 32 bits (%d, %x) o un puntero a string (%s)
		ventana	->	n�mero de ventana (de 0 a 3)
		
*/
void _gg_escribir(char *formato, unsigned int val1, unsigned int val2, int ventana)
{
	
	int fActual, numCar, i, espacio, iTemp, color;
	char car;
	char res[3*VCOLS+1];
	
	// Convertir el string de formato en un mensaje de texto definitivo:
	_gg_procesarFormato(formato,val1,val2,res);
	
	color = _gd_wbfs[ventana].pControl >> 28; // rango de colores: (0-3)
	fActual = (_gd_wbfs[ventana].pControl >> 16) & 0xFFF; 	// rango de filas: (0-23)
	numCar = _gd_wbfs[ventana].pControl & 0xFFFF;	// rango de car�cteres pendientes: (0-32)
	
	i = 0;
	car = res[i];
	while (car != '\0')
	{
		
		if ((car== '%') && (res[i+1] >= '0') && (res[i+1] <= '3'))
		{
			color =  res[i+1] - '0';
			i = i + 2;
			car = res[i];
		}
				
		if (car == '\t')
		{
			espacio = 4 - (numCar % 4);
			iTemp = 0;
			while ((iTemp < espacio) && (numCar < VCOLS))
			{
				_gd_wbfs[ventana].pChars[numCar++] = (' ' - 32) + color * 128;
				iTemp++;
			}
		}
		else if ((car != '\n') && (numCar < VCOLS))		// Si se trata de un car�cter literal
		{
			_gd_wbfs[ventana].pChars[numCar++] = (car - 32) + color * 128;
		}
		
		if ((car == '\n') || (numCar == VCOLS) )
		{
			_gp_WaitForVBlank();
			if ( fActual == VFILS)
			{
				_gg_desplazar(ventana);
				fActual--;
			}
			
			_gg_escribirLinea(ventana,fActual,numCar); 
			
			numCar = 0;
			fActual++;
		}
				
		_gd_wbfs[ventana].pControl = (color << 28) + (fActual  << 16) + numCar;
		car = res[++i];
	}
		
}
