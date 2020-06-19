package stream.mpi;

import align2.ListNum;

import stream.Read;
import stream.ConcurrentReadInputStream;
import stream.ConcurrentReadInputStreamD;
import stream.mpi.MPIWrapper;

/**
 * The MPI implementation of ConcurrentReadInputStreamD.
 * @author Jonathan Rood
 * @date Dec 9, 2014
 *
 */
public class ConcurrentReadInputStreamMPI extends ConcurrentReadInputStreamD {

	/**
	 * @param cris_
	 * @param master_
	 * @param keepAll_
	 */
	public ConcurrentReadInputStreamMPI(ConcurrentReadInputStream cris_, boolean master_, boolean keepAll_) {
		super(cris_, master_, keepAll_);
	}

	protected void broadcast(ListNum<Read> ln){
		//if(!keepAll && ln.size()>0){//Decide how to send this list
		if(!keepAll){//Decide how to send this list
			final int toRank=(int)(ln.id%ranks);
			if(toRank==rank){return;}
			unicast(ln, toRank);
			if(verbose){System.err.println("crisMPI:  Rank: " + rank + " unicasted to rank: " + toRank);}
			return;
		}
		MPIWrapper.broadcastList(ln);
		if(verbose){System.err.println("crisMPI:  Rank: " + rank + " broadcasted reads.");}
	}

	protected void unicast(ListNum<Read> ln, final int toRank){
		if(toRank==rank){return;}
		MPIWrapper.sendList(ln, toRank);
		if(verbose){System.err.println("crisMPI:  Rank: " + rank + " unicasted to rank: " + toRank);}
	}
	
	protected void broadcastPaired(boolean b){
		if(verbose){System.err.println("crisMPI:  Rank: " + rank + " broadcasting pairing status of " + b + ".");}
		MPIWrapper.broadcastBoolean(b);
	}

	protected void broadcastKeepall(boolean b){
		if(verbose){System.err.println("crisMPI:  Rank: " + rank + " broadcasting keepAll status of " + b + ".");}
		MPIWrapper.broadcastBoolean(b);
	}
	
	protected ListNum<Read> listen(){
		if(verbose){System.err.println("crisMPI:  Rank: " + rank + " listening for reads.");}
		return MPIWrapper.listenForListCris(0);
	}
	
	protected boolean listenPaired(){
		if(verbose){System.err.println("crisMPI:  Rank: " + rank + " listening for pairing status.");}
		boolean b=MPIWrapper.listenForBooleanFromBroadcast();
		if(verbose){System.err.println("crisMPI:  Rank: " + rank + " received paired status of " + b + ".");}
		return b;
	}

	protected boolean listenKeepall(){
		if(verbose){System.err.println("crisMPI:  Rank: " + rank + " listening for keepAll status.");}
		boolean b=MPIWrapper.listenForBooleanFromBroadcast();
		if(verbose){System.err.println("crisMPI:  Rank: " + rank + " received keepAll status of " + b + ".");}
		return b;
	}

	private boolean verbose=false;

}
