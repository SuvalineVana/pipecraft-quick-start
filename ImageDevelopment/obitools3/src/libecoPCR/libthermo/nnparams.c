/*
 *  nnparams.cpp
 *  PHunterLib
 *
 *  Nearest Neighbor Model / Parameters
 *
 *  Created by Tiayyba Riaz on 7/2/09.
 *
 */

#include <memory.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include "nnparams.h"

static char bpencoder[] = {	1,							// A
		                   	0,                          // b
		                   	2,                          // C
		                   	0,0,0,                      // d, e, f
		                   	3,                          // G
		                   	0,0,0,0,0,0,0,0,0,0,0,0,    // h,i,j,k,l,m,n,o,p,q,r,s
		                   	4,0,                        // T,U
		                   	0,0,0,0,0};                 // v,w,x,y,z


double forbidden_entropy;


double nparam_GetInitialEntropy(PNNParams nparm)
{
	return 	-5.9f+nparm->rlogc;
}


//Retrieve Enthalpy for given NN-Pair from parameter table
double nparam_GetEnthalpy(PNNParams nparm, char x0, char x1, char y0, char y1)
{
	return ndH(x0,x1,y0,y1); //xx, yx are already numbers
}


//Retrieve Entropy for given NN-Pair from parameter table
double nparam_GetEntropy(PNNParams nparm, char x0, char x1, char y0, char y1)
{
	//xx and yx are already numbers
	char nx0=x0;//nparam_convertNum(x0);
	char nx1=x1;//nparam_convertNum(x1);
	char ny0=y0;//nparam_convertNum(y0);
	char ny1=y1;//nparam_convertNum(y1);
	double answer = ndS(nx0,nx1,ny0,ny1);
	/*Salt correction Santalucia*/
	if (nparm->saltMethod == SALT_METHOD_SANTALUCIA) {
		if(nx0!=5 && 1<= nx1 && nx1<=4) {
			answer += 0.5*nparm->kfac;
		}
		if(ny1!=5 && 1<= ny0 && ny0<=4) {
			answer += 0.5*nparm->kfac;
		}
	}
	/*Salt correction Owczarzy*/
	if (nparm->saltMethod == SALT_METHOD_OWCZARZY) {
		double logk = log(nparm->kplus);
		answer += ndH(nx0,nx1,ny0,ny1)*((4.29 * nparm->gcContent-3.95)*0.00001*logk+ 0.0000094*logk*logk);
	}
	return answer;
}

/* PURPOSE:    Return melting temperature TM for given entropy and enthalpy
*              Assuming a one-state transition and using the formula
*                TM = dH / (dS + R ln(Ct/4))
*              entropy = dS + R ln Ct/4 (must already be included!)
*              enthaklpy = dH
*              where
*                dH = enthalpy
*                dS = entropy
*                R  = Boltzmann factor
*                Ct = Strand Concentration
*
*  PARAMETERS:
*	entrypy and enthalpy
*
*  RETURN VALUE:
* 	temperature
*/

double nparam_CalcTM(double entropy,double enthalpy)
{
	double tm = 0;               // absolute zero - return if model fails!
    if (enthalpy>=forbidden_enthalpy)   //||(entropy==-cfact))
		return 0;
	if (entropy<0)         // avoid division by zero and model errors!
	{
	  tm = enthalpy/entropy;// - kfac; //LKFEB
		if (tm<0)
			return 0;
	}
	return tm;
}


void nparam_InitParams(PNNParams nparm, double c1, double c2, double kp, int sm)
{
	nparm->Ct1 = c1;
	nparm->Ct2 = c2;
	nparm->kplus = kp;
	int maxCT = 1;
	if(nparm->Ct2 > nparm->Ct1)
	{
		maxCT = 2;
	}
	double ctFactor;
 	if(nparm->Ct1 == nparm->Ct2)
	{
		ctFactor = nparm->Ct1/2;
	}
	else if (maxCT == 1)
	{
		ctFactor = nparm->Ct1-nparm->Ct2/2;
	}
	else
	{
		ctFactor = nparm->Ct2-nparm->Ct1/2;
	}
	nparm->rlogc = R * log(ctFactor);
	forbidden_entropy = nparm->rlogc;
	nparm->kfac = 0.368 * log (nparm->kplus);
	nparm->saltMethod = sm;
	int x,y,a,b;  // variables used as counters...

	// Set all parameters to zero!
	memset(nparm->dH,0,sizeof(nparm->dH));
	memset(nparm->dS,0,sizeof(nparm->dS));

	// Set all X-/Y-, -X/Y- and X-/-Y so, that TM will be VERY small!
	for (x=1;x<=4;x++)
	{
		for (y=1;y<=4;y++)
		{
			ndH(0,x,y,0)=forbidden_enthalpy;
			ndS(0,x,y,0)=forbidden_entropy;
			ndH(x,0,0,y)=forbidden_enthalpy;
			ndS(x,0,0,y)=forbidden_entropy;
			ndH(x,0,y,0)=forbidden_enthalpy;
			ndS(x,0,y,0)=forbidden_entropy;
			// forbid X-/Y$ and X$/Y- etc., i.e. terminal must not be paired with gap!
			ndH(x,5,y,0)=forbidden_enthalpy;
			ndS(x,5,y,0)=forbidden_entropy;
			ndH(x,0,y,5)=forbidden_enthalpy;
			ndS(x,0,y,5)=forbidden_entropy;
			ndH(5,x,0,y)=forbidden_enthalpy;
			ndS(5,x,0,y)=forbidden_entropy;
			ndH(0,x,5,y)=forbidden_enthalpy;
			ndS(0,x,5,y)=forbidden_entropy;
			// forbid X$/-Y etc.
			ndH(x,5,0,y)=forbidden_enthalpy;
			ndS(x,5,0,y)=forbidden_entropy;
			ndH(x,0,5,y)=forbidden_enthalpy;
			ndS(x,0,5,y)=forbidden_entropy;
			ndH(5,x,y,0)=forbidden_enthalpy;
			ndS(5,x,y,0)=forbidden_entropy;
			ndH(0,x,y,5)=forbidden_enthalpy;
			ndS(0,x,y,5)=forbidden_entropy;

		}
		// also, forbid x-/-- and --/x-, i.e. no two inner gaps paired
		ndH(x,0,0,0)=forbidden_enthalpy;
		ndS(x,0,0,0)=forbidden_entropy;
		ndH(0,0,x,0)=forbidden_enthalpy;
		ndS(0,0,x,0)=forbidden_entropy;
		// x-/-$
		ndH(x,0,0,5)=forbidden_enthalpy;
		ndS(x,0,0,5)=forbidden_entropy;
		ndH(5,0,0,x)=forbidden_enthalpy;
		ndS(5,0,0,x)=forbidden_entropy;
		ndH(0,5,x,0)=forbidden_enthalpy;
		ndS(x,0,0,5)=forbidden_entropy;
		ndH(0,x,5,0)=forbidden_enthalpy;
		ndS(0,x,5,0)=forbidden_entropy;
	}
	// forbid --/--
	ndH(0,0,0,0)=forbidden_enthalpy;
	ndS(0,0,0,0)=forbidden_entropy;

	ndH(5,0,0,0)=forbidden_enthalpy;
	ndS(5,0,0,0)=forbidden_entropy;
	ndH(0,0,5,0)=forbidden_enthalpy;
	ndS(0,0,5,0)=forbidden_entropy;
	ndH(0,5,5,0)=forbidden_enthalpy;
	ndS(0,5,5,0)=forbidden_entropy;

	// Interior loops (double Mismatches)
    #define iloop_entropy -0.97f
    #define iloop_enthalpy 0.0f
	for (x=1; x<=4; x++)
		for (y=1; y<=4; y++)
			for (a=1; a<=4; a++)
				for (b=1; b<=4; b++)
					// AT and CG pair, and as A=1, C=2, G=3, T=4 this means
					// we have Watson-Crick pairs if (x+a==5) and (y+b)==5.
					if (!((x+a==5)||(y+b==5)))
					{
						// No watson-crick-pair, i.e. double mismatch!
						// set enthalpy/entropy to loop expansion!
						ndH(x,y,a,b) = iloop_enthalpy;
						ndS(x,y,a,b) = iloop_entropy;
					}

	// xy/-- and --/xy (Bulge Loops of size > 1)
    #define bloop_entropy -1.3f
    #define bloop_enthalpy 0.0f
	for (x=1; x<=4; x++)
		for (y=1; y<=4; y++)
		{
			ndH(x,y,0,0) = bloop_enthalpy;
			ndS(x,y,0,0) = bloop_entropy;
			ndH(0,0,x,y) = bloop_enthalpy;
			ndS(0,0,x,y) = bloop_entropy;
		}

    // x-/ya abd xa/y- as well as -x/ay and ax/-y
	// bulge opening and closing parameters with
	// adjacent matches / mismatches
	// obulge_mism and cbulge_mism chosen so high to avoid
	//     AAAAAAAAA
	//     T--G----T
	// being better than
	//     AAAAAAAAA
	//     TG------T
    #define obulge_match_H (-2.66f * 1000)
    #define obulge_match_S -14.22f
    #define cbulge_match_H (-2.66f * 1000)
    #define cbulge_match_S -14.22f
    #define obulge_mism_H (0.0f * 1000)
    #define obulge_mism_S -6.45f
    #define cbulge_mism_H 0.0f
    #define cbulge_mism_S -6.45f
	for (x=1; x<=4; x++)
		for (y=1; y<=4; y++)
			for (a=1; a<=4; a++)
			{
				if (x+y==5)  // other base pair matches!
				{
					ndH(x,0,y,a)=obulge_match_H;  // bulge opening
					ndS(x,0,y,a)=obulge_match_S;
					ndH(x,a,y,0)=obulge_match_H;
					ndS(x,a,y,0)=obulge_match_S;
					ndH(0,x,a,y)=cbulge_match_H;  // bulge closing
					ndS(0,x,a,y)=cbulge_match_S;
					ndH(a,x,0,y)=cbulge_match_H;
					ndS(a,x,0,y)=cbulge_match_S;
				}
				else
				{           // mismatch in other base pair!
					ndH(x,0,y,a)=obulge_mism_H;   // bulge opening
					ndS(x,0,y,a)=obulge_mism_S;
					ndH(x,a,y,0)=obulge_mism_H;
					ndS(x,a,y,0)=obulge_mism_S;
					ndH(0,x,a,y)=cbulge_mism_H;   // bulge closing
					ndS(0,x,a,y)=cbulge_mism_S;
					ndH(a,x,0,y)=cbulge_mism_H;
					ndS(a,x,0,y)=cbulge_mism_S;
				}
			}

	// Watson-Crick pairs (note that only ten are unique, as obviously
	// 5'-AG-3'/3'-TC-5'  =  5'-CT-3'/3'-GA-5' etc.
	ndH(1,1,4,4)=-7.6f*1000;  ndS(1,1,4,4)=-21.3f;   // AA/TT 04
	ndH(1,2,4,3)=-8.4f*1000;  ndS(1,2,4,3)=-22.4f;   // AC/TG adapted GT/CA
	ndH(1,3,4,2)=-7.8f*1000;  ndS(1,3,4,2)=-21.0f;   // AG/TC adapted CT/GA
	ndH(1,4,4,1)=-7.2f*1000;  ndS(1,4,4,1)=-20.4f;   // AT/TA 04
	ndH(2,1,3,4)=-8.5f*1000;  ndS(2,1,3,4)=-22.7f;   // CA/GT 04
	ndH(2,2,3,3)=-8.0f*1000;  ndS(2,2,3,3)=-19.9f;   // CC/GG adapted GG/CC
	ndH(2,3,3,2)=-10.6f*1000; ndS(2,3,3,2)=-27.2f;   // CG/GC 04
	ndH(2,4,3,1)=-7.8f*1000;  ndS(2,4,3,1)=-21.0f;   // CT/GA 04
	ndH(3,1,2,4)=-8.2f*1000;  ndS(3,1,2,4)=-22.2f;   // GA/CT 04
	ndH(3,2,2,3)=-9.8f*1000;  ndS(3,2,2,3)=-24.4f;   // GC/CG 04
	ndH(3,3,2,2)=-8.0f*1000;  ndS(3,3,2,2)=-19.9f;   // GG/CC 04
	ndH(3,4,2,1)=-8.4f*1000;  ndS(3,4,2,1)=-22.4f;   // GT/CA 04
	ndH(4,1,1,4)=-7.2f*1000;  ndS(4,1,1,4)=-21.3f;   // TA/AT 04
	ndH(4,2,1,3)=-8.2f*1000;  ndS(4,2,1,3)=-22.2f;   // TC/AG adapted GA/CT
	ndH(4,3,1,2)=-8.5f*1000;  ndS(4,3,1,2)=-22.7f;   // TG/AC adapted CA/GT
	ndH(4,4,1,1)=-7.6f*1000;  ndS(4,4,1,1)=-21.3f;   // TT/AA adapted AA/TT

    // A-C Mismatches (Values for pH 7.0)
	ndH(1,1,2,4)=7.6f*1000;   ndS(1,1,2,4)=20.2f;    // AA/CT
	ndH(1,1,4,2)=2.3f*1000;   ndS(1,1,4,2)=4.6f;     // AA/TC
	ndH(1,2,2,3)=-0.7f*1000;  ndS(1,2,2,3)=-3.8f;    // AC/CG
	ndH(1,2,4,1)=5.3f*1000;   ndS(1,2,4,1)=14.6f;    // AC/TA
	ndH(1,3,2,2)=0.6f*1000;   ndS(1,3,2,2)=-0.6f;    // AG/CC
	ndH(1,4,2,1)=5.3f*1000;   ndS(1,4,2,1)=14.6f;    // AT/CA
	ndH(2,1,1,4)=3.4f*1000;   ndS(2,1,1,4)=8.0f;     // CA/AT
	ndH(2,1,3,2)=1.9f*1000;   ndS(2,1,3,2)=3.7f;     // CA/GC
	ndH(2,2,1,3)=5.2f*1000;   ndS(2,2,1,3)=14.2f;    // CC/AG
	ndH(2,2,3,1)=0.6f*1000;   ndS(2,2,3,1)=-0.6f;    // CC/GA
	ndH(2,3,1,2)=1.9f*1000;   ndS(2,3,1,2)=3.7f;     // CG/AC
	ndH(2,4,1,1)=2.3f*1000;   ndS(2,4,1,1)=4.6f;     // CT/AA
	ndH(3,1,2,2)=5.2f*1000;   ndS(3,1,2,2)=14.2f;    // GA/CC
	ndH(3,2,2,1)=-0.7f*1000;  ndS(3,2,2,1)=-3.8f;    // GC/CA
	ndH(4,1,1,2)=3.4f*1000;   ndS(4,1,1,2)=8.0f;     // TA/AC
	ndH(4,2,1,1)=7.6f*1000;   ndS(4,2,1,1)=20.2f;    // TC/AA

	// C-T Mismatches
	ndH(1,2,4,4)=0.7f*1000;   ndS(1,2,4,4)=0.2f;     // AC/TT
	ndH(1,4,4,2)=-1.2f*1000;  ndS(1,4,4,2)=-6.2f;    // AT/TC
	ndH(2,1,4,4)=1.0f*1000;   ndS(2,1,4,4)=0.7f;     // CA/TT
	ndH(2,2,3,4)=-0.8f*1000;  ndS(2,2,3,4)=-4.5f;    // CC/GT
	ndH(2,2,4,3)=5.2f*1000;   ndS(2,2,4,3)=13.5f;    // CC/TG
	ndH(2,3,4,2)=-1.5f*1000;  ndS(2,3,4,2)=-6.1f;    // CG/TC
	ndH(2,4,3,2)=-1.5f*1000;  ndS(2,4,3,2)=-6.1f;    // CT/GC
	ndH(2,4,4,1)=-1.2f*1000;  ndS(2,4,4,1)=-6.2f;    // CT/TA
	ndH(3,2,2,4)=2.3f*1000;   ndS(3,2,2,4)=5.4f;     // GC/CT
	ndH(3,4,2,2)=5.2f*1000;   ndS(3,4,2,2)=13.5f;    // GT/CC
	ndH(4,1,2,4)=1.2f*1000;   ndS(4,1,2,4)=0.7f;     // TA/CT
	ndH(4,2,2,3)=2.3f*1000;   ndS(4,2,2,3)=5.4f;     // TC/CG
	ndH(4,2,1,4)=1.2f*1000;   ndS(4,2,1,4)=0.7f;     // TC/AT
	ndH(4,3,2,2)=-0.8f*1000;  ndS(4,3,2,2)=-4.5f;    // TG/CC
	ndH(4,4,2,1)=0.7f*1000;   ndS(4,4,2,1)=0.2f;     // TT/CA
	ndH(4,4,1,2)=1.0f*1000;   ndS(4,4,1,2)=0.7f;     // TT/AC

	// G-A Mismatches
	ndH(1,1,3,4)=3.0f*1000;   ndS(1,1,3,4)=7.4f;     // AA/GT
	ndH(1,1,4,3)=-0.6f*1000;  ndS(1,1,4,3)=-2.3f;    // AA/TG
	ndH(1,2,3,3)=0.5f*1000;   ndS(1,2,3,3)=3.2f;     // AC/GG
	ndH(1,3,3,2)=-4.0f*1000;  ndS(1,3,3,2)=-13.2f;   // AG/GC
	ndH(1,3,4,1)=-0.7f*1000;  ndS(1,3,4,1)=-2.3f;    // AG/TA
	ndH(1,4,3,1)=-0.7f*1000;  ndS(1,4,3,1)=-2.3f;    // AT/GA
	ndH(2,1,3,3)=-0.7f*1000;  ndS(2,1,3,3)=-2.3f;    // CA/GG
	ndH(2,3,3,1)=-4.0f*1000;  ndS(2,3,3,1)=-13.2f;   // CG/GA
	ndH(3,1,1,4)=0.7f*1000;   ndS(3,1,1,4)=0.7f;     // GA/AT
	ndH(3,1,2,3)=-0.6f*1000;  ndS(3,1,2,3)=-1.0f;    // GA/CG
	ndH(3,2,1,3)=-0.6f*1000;  ndS(3,2,1,3)=-1.0f;    // GC/AG
	ndH(3,3,1,2)=-0.7f*1000;  ndS(3,3,1,2)=-2.3f;    // GG/AC
	ndH(3,3,2,1)=0.5f*1000;   ndS(3,3,2,1)=3.2f;     // GG/CA
	ndH(3,4,1,1)=-0.6f*1000;  ndS(3,4,1,1)=-2.3f;    // GT/AA
	ndH(4,1,1,3)=0.7f*1000;   ndS(4,1,1,3)=0.7f;     // TA/AG
	ndH(4,3,1,1)=3.0f*1000;   ndS(4,3,1,1)=7.4f;     // TG/AA

	// G-T Mismatches
	ndH(1,3,4,4)=1.0f*1000;   ndS(1,3,4,4)=0.9f;     // AG/TT
	ndH(1,4,4,3)=-2.5f*1000;  ndS(1,4,4,3)=-8.3f;    // AT/TG
	ndH(2,3,3,4)=-4.1f*1000;  ndS(2,3,3,4)=-11.7f;   // CG/GT
	ndH(2,4,3,3)=-2.8f*1000;  ndS(2,4,3,3)=-8.0f;    // CT/GG
	ndH(3,1,4,4)=-1.3f*1000;  ndS(3,1,4,4)=-5.3f;    // GA/TT
	ndH(3,2,4,3)=-4.4f*1000;  ndS(3,2,4,3)=-12.3f;   // GC/TG
	ndH(3,3,2,4)=3.3f*1000;   ndS(3,3,2,4)=10.4f;    // GG/CT
	ndH(3,3,4,2)=-2.8f*1000;  ndS(3,3,4,2)=-8.0f;    // GG/TC
//	ndH(3,3,4,4)=5.8f*1000;   ndS(3,3,4,4)=16.3f;    // GG/TT
	ndH(3,4,2,3)=-4.4f*1000;  ndS(3,4,2,3)=-12.3f;   // GT/CG
	ndH(3,4,4,1)=-2.5f*1000;  ndS(3,4,4,1)=-8.3f;    // GT/TA
//	ndH(3,4,4,3)=4.1f*1000;   ndS(3,4,4,3)=9.5f;     // GT/TG
	ndH(4,1,3,4)=-0.1f*1000;  ndS(4,1,3,4)=-1.7f;    // TA/GT
	ndH(4,2,3,3)=3.3f*1000;   ndS(4,2,3,3)=10.4f;    // TC/GG
	ndH(4,3,1,4)=-0.1f*1000;  ndS(4,3,1,4)=-1.7f;    // TG/AT
	ndH(4,3,3,2)=-4.1f*1000;  ndS(4,3,3,2)=-11.7f;   // TG/GC
//	ndH(4,3,3,4)=-1.4f*1000;  ndS(4,3,3,4)=-6.2f;    // TG/GT
	ndH(4,4,1,3)=-1.3f*1000;  ndS(4,4,1,3)=-5.3f;    // TT/AG
	ndH(4,4,3,1)=1.0f*1000;   ndS(4,4,3,1)=0.9f;     // TT/GA
//	ndH(4,4,3,3)=5.8f*1000;   ndS(4,4,3,3)=16.3f;    // TT/GG

	// A-A Mismatches
	ndH(1,1,1,4)=4.7f*1000;   ndS(1,1,1,4)=12.9f;    // AA/AT
	ndH(1,1,4,1)=1.2f*1000;   ndS(1,1,4,1)=1.7f;     // AA/TA
	ndH(1,2,1,3)=-2.9f*1000;  ndS(1,2,1,3)=-9.8f;    // AC/AG
	ndH(1,3,1,2)=-0.9f*1000;  ndS(1,3,1,2)=-4.2f;    // AG/AC
	ndH(1,4,1,1)=1.2f*1000;   ndS(1,4,1,1)=1.7f;     // AT/AA
	ndH(2,1,3,1)=-0.9f*1000;  ndS(2,1,3,1)=-4.2f;    // CA/GA
    ndH(3,1,2,1)=-2.9f*1000;  ndS(3,1,2,1)=-9.8f;    // GA/CA
	ndH(4,1,1,1)=4.7f*1000;   ndS(4,1,1,1)=12.9f;    // TA/AA

	// C-C Mismatches
	ndH(1,2,4,2)=0.0f*1000;   ndS(1,2,4,2)=-4.4f;    // AC/TC
	ndH(2,1,2,4)=6.1f*1000;   ndS(2,1,2,4)=16.4f;    // CA/CT
	ndH(2,2,2,3)=3.6f*1000;   ndS(2,2,2,3)=8.9f;     // CC/CG
	ndH(2,2,3,2)=-1.5f*1000;  ndS(2,2,3,2)=-7.2f;    // CC/GC
	ndH(2,3,2,2)=-1.5f*1000;  ndS(2,3,2,2)=-7.2f;    // CG/CC
	ndH(2,4,2,1)=0.0f*1000;   ndS(2,4,2,1)=-4.4f;    // CT/CA
	ndH(3,2,2,2)=3.6f*1000;   ndS(3,2,2,2)=8.9f;     // GC/CC
	ndH(4,2,1,2)=6.1f*1000;   ndS(4,2,1,2)=16.4f;    // TC/AC

	// G-G Mismatches
	ndH(1,3,4,3)=-3.1f*1000;  ndS(1,3,4,3)=-9.5f;    // AG/TG
	ndH(2,3,3,3)=-4.9f*1000;  ndS(2,3,3,3)=-15.3f;   // CG/GG
	ndH(3,1,3,4)=1.6f*1000;   ndS(3,1,3,4)=3.6f;     // GA/GT
	ndH(3,2,3,3)=-6.0f*1000;  ndS(3,2,3,3)=-15.8f;   // GC/GG
	ndH(3,3,2,3)=-6.0f*1000;  ndS(3,3,2,3)=-15.8f;   // GG/CG
	ndH(3,3,3,2)=-4.9f*1000;  ndS(3,3,3,2)=-15.3f;   // GG/GC
	ndH(3,4,3,1)=-3.1f*1000;  ndS(3,4,3,1)=-9.5f;    // GT/GA
	ndH(4,3,1,3)=1.6f*1000;   ndS(4,3,1,3)=3.6f;     // TG/AG

	// T-T Mismatches
	ndH(1,4,4,4)=-2.7f*1000;  ndS(1,4,4,4)=-10.8f;   // AT/TT
	ndH(2,4,3,4)=-5.0f*1000;  ndS(2,4,3,4)=-15.8f;   // CT/GT
	ndH(3,4,2,4)=-2.2f*1000;  ndS(3,4,2,4)=-8.4f;    // GT/CT
	ndH(4,1,4,4)=0.2f*1000;   ndS(4,1,4,4)=-1.5f;    // TA/TT
	ndH(4,2,4,3)=-2.2f*1000;  ndS(4,2,4,3)=-8.4f;    // TC/TG
	ndH(4,3,4,2)=-5.0f*1000;  ndS(4,3,4,2)=-15.8f;   // TG/TC
	ndH(4,4,1,4)=0.2f*1000;   ndS(4,4,1,4)=-1.5f;    // TT/AT
	ndH(4,4,4,1)=-2.7f*1000;  ndS(4,4,4,1)=-10.8f;   // TT/TA

	// Dangling Ends
	ndH(5,1,1,4)=-0.7f*1000;  ndS(5,1,1,4)=-0.8f;    // $A/AT
	ndH(5,1,2,4)=4.4f*1000;   ndS(5,1,2,4)=14.9f;    // $A/CT
	ndH(5,1,3,4)=-1.6f*1000;  ndS(5,1,3,4)=-3.6f;    // $A/GT
	ndH(5,1,4,4)=2.9f*1000;   ndS(5,1,4,4)=10.4f;    // $A/TT
	ndH(5,2,1,3)=-2.1f*1000;  ndS(5,2,1,3)=-3.9f;    // $C/AG
	ndH(5,2,2,3)=-0.2f*1000;  ndS(5,2,2,3)=-0.1f;    // $C/CG
	ndH(5,2,3,3)=-3.9f*1000;  ndS(5,2,3,3)=-11.2f;   // $C/GG
	ndH(5,2,4,3)=-4.4f*1000;  ndS(5,2,4,3)=-13.1f;   // $C/TG
	ndH(5,3,1,2)=-5.9f*1000;  ndS(5,3,1,2)=-16.5f;   // $G/AC
	ndH(5,3,2,2)=-2.6f*1000;  ndS(5,3,2,2)=-7.4f;    // $G/CC
	ndH(5,3,3,2)=-3.2f*1000;  ndS(5,3,3,2)=-10.4f;   // $G/GC
	ndH(5,3,4,2)=-5.2f*1000;  ndS(5,3,4,2)=-15.0f;   // $G/TC
	ndH(5,4,1,1)=-0.5f*1000;  ndS(5,4,1,1)=-1.1f;    // $T/AA
	ndH(5,4,2,1)=4.7f*1000;   ndS(5,4,2,1)=14.2f;    // $T/CA
	ndH(5,4,3,1)=-4.1f*1000;  ndS(5,4,3,1)=-13.1f;   // $T/GA
	ndH(5,4,4,1)=-3.8f*1000;  ndS(5,4,4,1)=-12.6f;   // $T/TA
	ndH(1,5,4,1)=-2.9f*1000;  ndS(1,5,4,1)=-7.6f;    // A$/TA
	ndH(1,5,4,2)=-4.1f*1000;  ndS(1,5,4,2)=-13.0f;   // A$/TC
	ndH(1,5,4,3)=-4.2f*1000;  ndS(1,5,4,3)=-15.0f;   // A$/TG
	ndH(1,5,4,4)=-0.2f*1000;  ndS(1,5,4,4)=-0.5f;    // A$/TT
	ndH(1,1,5,4)=0.2f*1000;   ndS(1,1,5,4)=2.3f;     // AA/$T
	ndH(1,1,4,5)=-0.5f*1000;  ndS(1,1,4,5)=-1.1f;    // AA/T$
	ndH(1,2,5,3)=-6.3f*1000;  ndS(1,2,5,3)=-17.1f;   // AC/$G
	ndH(1,2,4,5)=4.7f*1000;   ndS(1,2,4,5)=14.2f;    // AC/T$
	ndH(1,3,5,2)=-3.7f*1000;  ndS(1,3,5,2)=-10.0f;   // AG/$C
	ndH(1,3,4,5)=-4.1f*1000;  ndS(1,3,4,5)=-13.1f;   // AG/T$
	ndH(1,4,5,1)=-2.9f*1000;  ndS(1,4,5,1)=-7.6f;    // AT/$A
	ndH(1,4,4,5)=-3.8f*1000;  ndS(1,4,4,5)=-12.6f;   // AT/T$
	ndH(2,5,3,1)=-3.7f*1000;  ndS(2,5,3,1)=-10.0f;   // C$/GA
	ndH(2,5,3,2)=-4.0f*1000;  ndS(2,5,3,2)=-11.9f;   // C$/GC
	ndH(2,5,3,3)=-3.9f*1000;  ndS(2,5,3,3)=-10.9f;   // C$/GG
	ndH(2,5,3,4)=-4.9f*1000;  ndS(2,5,3,4)=-13.8f;   // C$/GT
	ndH(2,1,5,4)=0.6f*1000;   ndS(2,1,5,4)=3.3f;     // CA/$T
	ndH(2,1,3,5)=-5.9f*1000;  ndS(2,1,3,5)=-16.5f;   // CA/G$
	ndH(2,2,5,3)=-4.4f*1000;  ndS(2,2,5,3)=-12.6f;   // CC/$G
	ndH(2,2,3,5)=-2.6f*1000;  ndS(2,2,3,5)=-7.4f;    // CC/G$
	ndH(2,3,5,2)=-4.0f*1000;  ndS(2,3,5,2)=-11.9f;   // CG/$C
	ndH(2,3,3,5)=-3.2f*1000;  ndS(2,3,3,5)=-10.4f;   // CG/G$
	ndH(2,4,5,1)=-4.1f*1000;  ndS(2,4,5,1)=-13.0f;   // CT/$A
	ndH(2,4,3,5)=-5.2f*1000;  ndS(2,4,3,5)=-15.0f;   // CT/G$
	ndH(3,5,2,1)=-6.3f*1000;  ndS(3,5,2,1)=-17.1f;   // G$/CA
	ndH(3,5,2,2)=-4.4f*1000;  ndS(3,5,2,2)=-12.6f;   // G$/CC
	ndH(3,5,2,3)=-5.1f*1000;  ndS(3,5,2,3)=-14.0f;   // G$/CG
	ndH(3,5,2,4)=-4.0f*1000;  ndS(3,5,2,4)=-10.9f;   // G$/CT
	ndH(3,1,5,4)=-1.1f*1000;  ndS(3,1,5,4)=-1.6f;    // GA/$T
	ndH(3,1,2,5)=-2.1f*1000;  ndS(3,1,2,5)=-3.9f;    // GA/C$
	ndH(3,2,5,3)=-5.1f*1000;  ndS(3,2,5,3)=-14.0f;   // GC/$G
	ndH(3,2,2,5)=-0.2f*1000;  ndS(3,2,2,5)=-0.1f;    // GC/C$
	ndH(3,3,5,2)=-3.9f*1000;  ndS(3,3,5,2)=-10.9f;   // GG/$C
	ndH(3,3,2,5)=-3.9f*1000;  ndS(3,3,2,5)=-11.2f;   // GG/C$
	ndH(3,4,5,1)=-4.2f*1000;  ndS(3,4,5,1)=-15.0f;   // GT/$A
	ndH(3,4,2,5)=-4.4f*1000;  ndS(3,4,2,5)=-13.1f;   // GT/C$
	ndH(4,5,1,1)=0.2f*1000;   ndS(4,5,1,1)=2.3f;     // T$/AA
	ndH(4,5,1,2)=0.6f*1000;   ndS(4,5,1,2)=3.3f;     // T$/AC
	ndH(4,5,1,3)=-1.1f*1000;  ndS(4,5,1,3)=-1.6f;    // T$/AG
	ndH(4,5,1,4)=-6.9f*1000;  ndS(4,5,1,4)=-20.0f;   // T$/AT
	ndH(4,1,5,4)=-6.9f*1000;  ndS(4,1,5,4)=-20.0f;   // TA/$T
	ndH(4,1,1,5)=-0.7f*1000;  ndS(4,1,1,5)=-0.7f;    // TA/A$
	ndH(4,2,5,3)=-4.0f*1000;  ndS(4,2,5,3)=-10.9f;   // TC/$G
	ndH(4,2,1,5)=4.4f*1000;   ndS(4,2,1,5)=14.9f;    // TC/A$
	ndH(4,3,5,2)=-4.9f*1000;  ndS(4,3,5,2)=-13.8f;   // TG/$C
	ndH(4,3,1,5)=-1.6f*1000;  ndS(4,3,1,5)=-3.6f;    // TG/A$
	ndH(4,4,5,1)=-0.2f*1000;  ndS(4,4,5,1)=-0.5f;    // TT/$A
	ndH(4,4,1,5)=2.9f*1000;   ndS(4,4,1,5)=10.4f;    // TT/A$

	return;
}

int nparam_CountGCContent(char * seq ) {
	int lseq = strlen(seq);
	int k;
	double count = 0;
	for( k=0;k<lseq;k++) {
		if (seq[k] == 'G' || seq[k] == 'C' ) {
			count+=1;
		}
	}
	return count;
}

void nparam_CleanSeq (const char* inseq, char* outseq, int len)
{
	int seqlen = strlen (inseq);
	int i, j;

	if (len != 0)
		seqlen = len;

	outseq[0]='x';

	for (i = 0, j = 0; i < seqlen && outseq[0]; i++,j++)
	{
		switch (inseq[i])
		{
		case 'a':
		case '\0':
		case 'A':
			outseq[j] = 'A'; break;
		case 'c':
		case '\1':
		case 'C':
			outseq[j] = 'C'; break;
		case 'g':
		case '\2':
		case 'G':
			outseq[j] = 'G'; break;
		case 't':
		case '\3':
		case 'T':
			outseq[j] = 'T'; break;
		default:
			outseq[0]=0;
		}
	}
	outseq[j] = '\0';
}

//Calculate TM for given sequence against its complement
double nparam_CalcSelfTM(PNNParams nparm, char* seq, int len)
{
	const unsigned long long minus1 = 0xFFFFFFFFFFFFFFFFLLU;
	const double NaN = *((double*)&minus1);
	double thedH = 0;
	//double thedS = nparam_GetInitialEntropy(nparm);
	double thedS = -5.9f+nparm->rlogc;
	double mtemp;
	unsigned char c1;
	unsigned char c2;
	unsigned char c3;
	unsigned char c4;
	unsigned int i;
	char nseq[50];
	char *useq = seq;

	nparam_CleanSeq (seq, nseq, len);
	if (!nseq[0])
	         return NaN;
	useq = nseq;

	for ( i=1;i<len;i++)
	{
		c1 = GETREVCODE(useq[i-1]); //nparam_getComplement(seq[i-1],1);
		c2 = GETREVCODE(useq[i]); //nparam_getComplement(seq[i],1);
		c3 = GETNUMCODE(useq[i-1]);
		c4 = GETNUMCODE(useq[i]);


		thedH += nparm->dH[c3][c4][c1][c2];//nparam_GetEnthalpy(nparm, c3,c4,c1,c2);
		thedS += nparam_GetEntropy(nparm, c3,c4,c1,c2);
	}
	//printf("------------------\n");
	mtemp = nparam_CalcTM(thedS,thedH);
		//fprintf(stderr,"Enthalpy: %f, entropy: %f, seq: %s  rloc=%f\n", thedH, thedS, useq, nparm->rlogc);
		//exit (0);
	return mtemp;
}

double nparam_CalcTwoTM(PNNParams nparm, const char* seq1, const char* seq2, int len)
{
	const unsigned long long minus1 = 0xFFFFFFFFFFFFFFFFLLU;
	const double NaN = *((double*)&minus1);
	double thedH = 0;
	//double thedS = nparam_GetInitialEntropy(nparm);
	double thedS = -5.9f+nparm->rlogc;
	double mtemp;
	unsigned char c1;
	unsigned char c2;
	unsigned char c3;
	unsigned char c4;
	unsigned int i;
	char nseq1[50];
	char nseq2[50];
	char *useq1;
	char *useq2;

	nparam_CleanSeq (seq1, nseq1, len);
	if (!nseq1[0])
	         return NaN;
	useq1 = nseq1;

	nparam_CleanSeq (seq2, nseq2, len);
	if (!nseq2[0])
	         return NaN;
	useq2 = nseq2;

	//fprintf (stderr,"Primer : %s\n",useq);
	for ( i=1;i<len;i++)
	{
		c1 = GETREVCODE(useq2[i-1]); //nparam_getComplement(seq[i-1],1);
		c2 = GETREVCODE(useq2[i]);   //nparam_getComplement(seq[i],1);
		c3 = GETNUMCODE(useq1[i-1]);
		c4 = GETNUMCODE(useq1[i]);

		//fprintf (stderr,"Primer : %s %f %f %d %d, %d %d %f\n",useq,thedH,thedS,(int)c3,(int)c4,(int)c1,(int)c2,nparam_GetEnthalpy(nparm, c3,c4,c1,c2));

		thedH += nparm->dH[c3][c4][c1][c2];//nparam_GetEnthalpy(nparm, c3,c4,c1,c2);
		thedS += nparam_GetEntropy(nparm, c3,c4,c1,c2);
	}
	//fprintf(stderr,"------------------\n");
	mtemp = nparam_CalcTM(thedS,thedH);
	//if (mtemp == 0)
	//{
	//	fprintf(stderr,"Enthalpy: %f, entropy: %f, seq: %s\n", thedH, thedS, useq);
		//exit (0);
	//}
	return mtemp;
}

double calculateMeltingTemperatureBasic (char * seq) {
	int gccount;
	double temp;
	int seqlen;

	seqlen = strlen (seq);
	gccount = nparam_CountGCContent (seq);
	temp = 64.9 + 41*(gccount - 16.4)/seqlen;
	return temp;
}
