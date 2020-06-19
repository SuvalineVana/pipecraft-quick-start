package clump;

import java.util.ArrayList;
import java.util.Arrays;

import dna.AminoAcid;

import align2.Tools;

import stream.Read;

/**
 * A list of reads sharing a kmer.
 * @author Brian Bushnell
 * @date Nov 7, 2015
 *
 */
public class Clump extends ArrayList<Read> {
			
	public Clump(long kmer_){
		this(kmer_, 8);
	}

	public Clump(long kmer_, int size){
		super(size);
		kmer=kmer_;
	}

	public boolean add(Read r){
		long[] obj=(long[]) r.obj;
		assert(obj[0]==kmer);
		return super.add(r);
	}
	
	/** This will create a count consensus of the bases at each position in the cluster. */
	public int[][] baseCounts(){
		int maxLeft=-1, maxRight=-1;
		for(Read r : this){
			long[] obj=(long[]) r.obj;
			int pos=(int)obj[1];
			maxLeft=Tools.max(maxLeft, pos);
			maxRight=Tools.max(maxRight, r.length()-pos);
		}
		final int width=maxLeft+maxRight;
//		assert(size()==1) : "\nleft="+maxLeft+", right="+maxRight+", width="+width+", "+k+"\n"+get(0).toFastq()+"\n"+get(size()-1).toFastq();
		
//		System.err.println("\n\n");
		final int[][] counts=new int[4][width];
		for(Read r : this){
			long[] obj=(long[]) r.obj;
			int pos=(int)obj[1];
			byte[] bases=r.bases, quals=r.quality;
//			System.err.println("pos="+pos+", maxLeft="+maxLeft);
			for(int cloc=0, rloc=maxLeft-pos; cloc<bases.length; cloc++, rloc++){
//				System.err.println("cloc="+cloc+"/"+bases.length+", rloc="+rloc+"/"+width);
				int x=AminoAcid.baseToNumber[bases[cloc]];
				if(x>-1){
					int q=(quals==null ? 20 : quals[cloc]);
					counts[x][rloc]+=q;
				}
			}
		}
//		if(size()>0){//Looks correct.
//			System.err.println(Arrays.toString(counts[0]));
//			System.err.println(Arrays.toString(counts[1]));
//			System.err.println(Arrays.toString(counts[2]));
//			System.err.println(Arrays.toString(counts[3]));
//		}
		return counts;
	}
	
	
	public ArrayList<Read> condense(){
		//TODO - this needs to be expanded.  Consensus is not good enough.
		Read r=consensus();
		ArrayList<Read> list=new ArrayList<Read>();
		list.add(r);
		return list;
	}
	
	public Read consensus(){//TODO: Return single read if only 1.
		final int[][] counts=baseCounts();
		final int width=counts[0].length;
		byte[] bases=new byte[width], quals=new byte[width];
		for(int i=0; i<width; i++){
			int x=getConsensus(counts, i);
			if(x<0){
//				System.err.println("q="+0+", x="+x+"; A="+counts[0][i]+", C="+counts[1][i]+", G="+counts[2][i]+", T="+counts[3][i]);
				bases[i]='N';
				quals[i]=0;
			}else{
				long q=2*counts[x][i]-counts[0][i]-counts[1][i]-counts[2][i]-counts[3][i];
//				System.err.println("q="+q+", x="+x+"; A="+counts[0][i]+", C="+counts[1][i]+", G="+counts[2][i]+", T="+counts[3][i]);
				bases[i]=AminoAcid.numberToBase[x];
				quals[i]=(byte)Tools.mid(0, q, 50);
			}
		}
		Read leftmost=this.get(0);
		Read r=new Read(bases, quals, 0, leftmost.id);
		//TODO: Attach the long pair, and make sure the kmer location is correct.
//		assert(false) : "\n"+r.toFastq()+"\nCheck kmer location.";
//		assert(size()==1) : "\n"+r.toFastq()+"\n"+get(0).toFastq()+"\n"+get(size()-1).toFastq()+"\n";
		return r;
	}
	
	public int getConsensus(int[][] counts, int pos){
		int xMax=0;
		for(int x=1; x<4; x++){
//			System.err.println("x="+x+", max="+max+", Checking "+counts[x][pos]+" vs "+counts[x][max]);
			if(counts[x][pos]>counts[xMax][pos]){xMax=x;}
		}
//		assert(counts[max][pos]>=counts[0][pos]);
//		assert(counts[max][pos]>=counts[1][pos]);
//		assert(counts[max][pos]>=counts[2][pos]) : max+", "+counts[max][pos]+", ["+counts[0][pos]+", "+counts[1][pos]+", "+counts[2][pos]+", "+counts[3][pos]+"]";
//		assert(counts[max][pos]>=counts[3][pos]);
		return (counts[xMax][pos]>0 ? xMax : -1);
	}
	
	public final long kmer;
	
	public static int k=31;
	private static final long serialVersionUID = 1L;
	
}
