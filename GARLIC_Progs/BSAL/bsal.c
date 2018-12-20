/*------------------------------------------------------------------------------

	"BSAL.c" : primer programa de prueba para el sistema operativo GARLIC 1.0;
	
	El Bubble Sort és un senzill algorisme d'ordenació sobre una llista de 
	(arg + 1)*10 elements numeros aleatoris de 32 bits (0-65535). Funciona 
	revisant cada element de la llista a ordenar amb el següent, intercanviant-de 
	posició si estan en l'ordre equivocat.
	
	AVIS: per veure si funciona correcte els numeros aleatoris generen en 
	un rang [0-100].

------------------------------------------------------------------------------*/

#include <GARLIC_API.h>			/* definición de las funciones API de GARLIC */

int _start(int arg)				/* función de inicio : no se usa 'main' */
{
	int length, i, j;
	 
	if (arg < 0) arg = 0;			// limitar valor máximo y 
	else if (arg > 3) arg = 3;		// valor mínimo del argumento
	
	length = (arg + 1)*10;
	int vector[length];
	
	GARLIC_printf("-- Programa BSAL  -  PID (%d) --\n", GARLIC_pid());
	GARLIC_printf("\n");
	
	/****** Generem vector de length posicioes en rang [0-100] ******/
	for(i=0;i<length;i++)
	{
		vector[i]=GARLIC_random()%100;
		
	}
	
	/****** Imprimim vector generat ******/
	/*
	GARLIC_printf("\n(%d) Vector de %d elements desordenat \n",GARLIC_pid(), length);
	for(i=0;i<length;i++)
	{
		GARLIC_printf("\n(%d) %d",GARLIC_pid(),vector[i]);	
	}
	*/
	GARLIC_printf("%2Vector de %d elements desordenat%3", length);
	GARLIC_printf("[");	
	for(i=0;i<length;i++)
	{
		GARLIC_printf("%d, ",vector[i]);	
	}
	GARLIC_printf("]"); 
	
	/****** Ordenem el vector per algoritme Buble sort ******/
	for(i = 0 ; i < length - 1; i++) 
	{ 
       for(j = 0 ; j < length - i - 1 ; j++) 
	   {  
           if(vector[j] > vector[j+1]) {           
              int tmp = vector[j];
              vector[j]=vector[j+1];
              vector[j+1] = tmp; 
           }
        }
    }
	
	/****** Imprimim els resultats ******/
	/*
	GARLIC_printf("\n(%d) Vector de %d elements ordenat \n",GARLIC_pid(), length);
	for(i=0;i<length;i++)
	{
		GARLIC_printf("\n(%d) %d\n",GARLIC_pid(),vector[i]);	
	}
	*/
	
	GARLIC_printf("\n");
	
	GARLIC_printf("\n%2Vector de %d elements ordenat %1\n",GARLIC_pid(), length);
	GARLIC_printf("[");
	for(i=0;i<length;i++)
	{
		GARLIC_printf("%d, ",vector[i]);
	}
	GARLIC_printf("]"); 
	
	return 0;
}
