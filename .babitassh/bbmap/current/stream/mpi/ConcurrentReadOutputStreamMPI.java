package stream.mpi;

import align2.ListNum;

import stream.Read;
import stream.ConcurrentReadOutputStream;
import stream.ConcurrentReadOutputStreamD;
import stream.mpi.MPIWrapper;

/**
 * The MPI implementation of ConcurrentReadOutputStreamD.
 * @author Jonathan Rood
 * @date Dec 9, 2014
 *
 */
public class ConcurrentReadOutputStreamMPI extends ConcurrentReadOutputStreamD {

	/**
	 * @param cros_
	 * @param master_
	 */
	public ConcurrentReadOutputStreamMPI(ConcurrentReadOutputStream cros_, boolean master_) {
		super(cros_, master_);
	}

	@Override
	protected void unicast(ListNum<Read> ln, final int toRank){
		if(toRank==rank){return;}
		MPIWrapper.sendList(ln, toRank);
		if(verbose){System.err.println("crosMPI:  Rank: " + rank + " unicasted to rank: " + toRank);}
	}
	
	@Override
	protected ListNum<Read> listen(final int fromRank){
		if(verbose){System.err.println("crosMPI:  Rank: " + rank + " listening for reads from rank " + fromRank + ".");}
		return MPIWrapper.listenForListCros(fromRank);
	}
	
	@Override
	protected boolean listenForJoin(){
		if(verbose){System.err.println("crosMPI:  Rank: " + rank + " listening for join status.");}
		boolean b=MPIWrapper.listenForBooleanFromBroadcast();
		if(verbose){System.err.println("crosMPI:  Rank: " + rank + " received join status of " + b + ".");}
		return b;
	}

	@Override
	protected boolean listenFinishedSuccessfully(){
		if(verbose){System.err.println("crosMPI:  Rank: " + rank + " listening for finished successfully status.");}
		boolean b=MPIWrapper.listenForBooleanFromBroadcast();
		if(verbose){System.err.println("crosMPI:  Rank: " + rank + " received finished successfully status of " + b + ".");}
		return b;
	}

	@Override
	protected void broadcastJoin(boolean b){
		if(verbose){System.err.println("crosMPI:  Rank: " + rank + " broadcasting join status of " + b + ".");}
		MPIWrapper.broadcastBoolean(b);
	}

	@Override
	protected void broadcastFinishedSuccessfully(boolean b){
		if(verbose){System.err.println("crosMPI:  Rank: " + rank + " broadcasting finished successfully status.");}
		MPIWrapper.broadcastBoolean(b);
	}

	private boolean verbose=false;

}
