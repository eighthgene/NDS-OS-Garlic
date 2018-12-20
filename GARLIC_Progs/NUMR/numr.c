/*------------------------------------------------------------------------------

	"numr.c" : programa propio implementado, requerido  obligatoriamente
				(versión 1.0)
	 
	Muestra los números reversibles de dos dígits ( rango [10..2^(6*(arg+1))] ) a partir de una
	lista aleatoria con longitug de (arg+1)*10.
	Cabe recalcar que un número es resible si  al ser sumado a sí mismo tras invertir 
	sus dígitos da como resultado un número en el que todos los dígitos son impares. Y además,
	hay que cumplir que el longitud de los dos números, original y invertido, es igual.
	Por ejemplo, el número 25 es reversible pues 25 + 52 = 77, y los dos dígitos de 99
	son impares.

------------------------------------------------------------------------------*/

#include <GARLIC_API.h>			/* definición de las funciones API de GARLIC */

/* Función que devuelve un número invertido a partir de un número pasado por parámetro. */
unsigned int revertir_numero(unsigned int num)
{
	unsigned int  numRevertido = 0, resto;

    while(num != 0)
    {
		GARLIC_divmod(num, 10, &num, &resto); 
		// resto = num%10;
		// num /= 10;
        numRevertido = numRevertido*10 + resto;
    }
	
	return numRevertido;
}

/* Función que nos indique el número de dígitos que contiene un número pasado por parámetro */
unsigned int cuenta_digitos(unsigned int num) 
{
	unsigned int cont = 0, temp;
	
	while(num != 0)
    {       
		GARLIC_divmod(num, 10, &num, &temp);
        // num /= 10;
		cont++;
    }
	
	return cont;
	
}

/* Función que a partir de un número pasado como el único argumento, nos informe si todos sus dígitos son impares. */
unsigned char son_digitos_impares(unsigned int num)
{
	unsigned char sonImpares = 1;
	unsigned int resto;
	
	if (num == 0) sonImpares = 0;
	
	while( ( num != 0) && ( sonImpares) )
    {
        
		GARLIC_divmod(num, 10, &num, &resto); 
		// resto = num%10;
		// num /= 10;
		sonImpares = (resto & 1);
		/*
		GARLIC_divmod(resto, 2, &temp, &res);
		if ( res == 0) sonImpares = 0;
		*/     
    }
	
	return sonImpares;
}


//------------------------------------------------------------------------------
int _start(int arg)
//------------------------------------------------------------------------------
{
	
	if (arg < 0) arg = 0;			// limitar valor máximo y 
	else if (arg > 3) arg = 3;		// valor mínimo del argumento
	
	unsigned int lista[(arg+1)*10]; // lista de números originales
	unsigned int listaInv[(arg+1)*10]; // lista de números invertidos
	unsigned int listaRes[(arg+1)*10]; // lista de números resultantes, los que son reversibles
	unsigned int i,numAzar,temp, cont1, cont2,iRes = 0;
	unsigned int rangMax = 1 << (6*(arg+1)); // definición del rango máximo: 2^(6*(arg+1))
	
	GARLIC_printf("-Numeros reversibles- PID (%d)-\n", GARLIC_pid());
	
	for (i = 0; i < ((arg+1)*10); i++)
	{
		GARLIC_divmod(GARLIC_random(),rangMax, &temp, &numAzar); // generamos valor aleatorio dentro del rango máximo permitido
		if (numAzar < 10) numAzar += (arg+1)*10; // limitamos el valor mínimo, como mínimo de 2 dígitos
		lista[i] = numAzar;
		temp = revertir_numero(numAzar);
		cont1 = cuenta_digitos(numAzar);
		cont2 = cuenta_digitos(temp);
		if ( (cont1 == cont2) && (son_digitos_impares(numAzar+temp))) // si cumple las condiciones necesarias descritas en el principio,
			listaRes[iRes++] = numAzar; // entonces, el número genrado es reversible
		listaInv[i] = temp;
	}
	
	// Mostramos las informaciones resultantes en la pantalla:
	GARLIC_printf("\n%0Numeros originales: %3 \n");
	for (i = 0; i < ((arg+1)*10); i++)
		GARLIC_printf("%d \t",lista[i]);
	
	GARLIC_printf(" \n");
	GARLIC_printf("\n%0Numeros invertidos: %1\n");
	for (i = 0; i < ((arg+1)*10); i++)
		GARLIC_printf("%d \t",listaInv[i]);
	
	GARLIC_printf(" \n");
	GARLIC_printf("\n%0Numeros que son reversibles:%2\n");
	if ( iRes != 0)
	{
		for (i = 0; i < iRes; i++)
			GARLIC_printf("%d \t",listaRes[i]);
		
		GARLIC_printf(" \n");
	}
	else 
	{
		GARLIC_printf("\nNo hay ninguno!\n");
	}
	
	return 0;

}