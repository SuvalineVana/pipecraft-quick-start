package stream.mpi;

import mpi.*;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

import java.nio.ByteBuffer;

import align2.Shared;
import align2.ListNum;

import stream.Read;

/**
 * Wraps MPI class functions for access by other programs.
 * All MPI calls should go through this class.
 * It should also set Shared.MPI fields such as MPI_RANK.
 * 
 * @author Jonathan Rood
 * @date Dec 9, 2014
 *
 */

public class MPIWrapper {

	public static void mpiInit(String[] args) {
		if(Shared.USE_MPI && Shared.USE_CRISMPI) {
			if(verbose){System.out.println("Running MPI Init.");}
			if(!blocking) {
				bb=new ByteBuffer[msgsInFlight];
				bbLength=new ByteBuffer[msgsInFlight];
				iReq=new Request[msgsInFlight];
				iReqLength=new Request[msgsInFlight];
				n=-1;
				for(int i=0; i<msgsInFlight; i++){
					bb[i]=null;
					bbLength[i]=null;
					iReq[i]=null;
					iReqLength[i]=null;
				}
			}
			try {
				MPI.Init(args);
				Shared.MPI_RANK=MPI.COMM_WORLD.getRank();
				Shared.MPI_NUM_RANKS=MPI.COMM_WORLD.getSize();
			} catch (MPIException e) {
				e.printStackTrace();
			}
		}
		if(verbose){System.err.println("MPI:      Rank " + Shared.MPI_RANK + " finished MPI Init.");}
	}

	public static void mpiFinalize() {
		if(Shared.USE_MPI && Shared.USE_CRISMPI) {
			if(verbose){System.err.println("MPI:      Rank " + Shared.MPI_RANK + " running MPI Finalize.");}
			try {
				//MPI.COMM_WORLD.barrier();
				MPI.Finalize();
			} catch (MPIException e) {
				e.printStackTrace();
			}
		}
	}

	public static void broadcastList(ListNum<Read> ln){
		if(blocking){
			blockingBroadcastList(ln); //blocking
		}else{
			nonblockingBroadcastList(ln); //non-blocking
		}
	}

	private static void blockingBroadcastList(ListNum<Read> ln){
		byte[] b=serialize(ln);
		int[] bLength={b.length};
		if(verbose){System.err.println("MPI:      Rank " + Shared.MPI_RANK + " broadcasting message of size " + bLength[0] + ".");}
		try {
			MPI.COMM_WORLD.bcast(bLength,1,MPI.INT,0); // can't probe a broadcast, so send message size first
			MPI.COMM_WORLD.bcast(b,b.length,MPI.BYTE,0); // broadcast the actual message
		} catch (MPIException e) {
			e.printStackTrace();
		}
	}

	public static void sendList(ListNum<Read> ln, final int toRank){
		if(blocking){
			blockingSendList(ln, toRank); //blocking
		}else{
			nonblockingSendList(ln, toRank); //non-blocking
		}
	}

	private static void blockingSendList(ListNum<Read> ln, final int toRank){
		byte[] b=serialize(ln);
		if(verbose){System.err.println("MPI:      Rank " + Shared.MPI_RANK + " sending message of size " + b.length + " to rank " + toRank + ".");}
		try {
			MPI.COMM_WORLD.send(b,b.length,MPI.BYTE,toRank,50);
		} catch (MPIException e) {
			e.printStackTrace();
		}
	}

	private static void nonblockingSendList(ListNum<Read> ln, final int toRank){
		n++;
		int m=(int)(n%msgsInFlight);
		byte[] b=serialize(ln);
		if(iReq[m]!=null) {
			try {
				iReq[m].waitFor(); // wait on oldest message in flight
			} catch (MPIException e) {
				e.printStackTrace();
			}
		}
		bb[m]=ByteBuffer.allocateDirect(b.length);
		bb[m].put(b);
		bb[m].clear();
		if(verbose){System.err.println("MPI:      Rank " + Shared.MPI_RANK + " sending message of size " + b.length + " to rank " + toRank + ".");}
		try {
			iReq[m]=MPI.COMM_WORLD.iSend(bb[m],b.length,MPI.BYTE,toRank,50);
		} catch (MPIException e) {
			e.printStackTrace();
		}
	}

	private static void nonblockingBroadcastList(ListNum<Read> ln){
		n++;
		int m=(int)(n%msgsInFlight);
		byte[] b=serialize(ln);
		int[] bLength={b.length};
		if(iReqLength[m]!=null) {
			try {
				iReqLength[m].waitFor();
			} catch (MPIException e) {
				e.printStackTrace();
			}
		}
		bbLength[m]=ByteBuffer.allocateDirect(4);
		bbLength[m].putInt(bLength[0]);
		bbLength[m].clear();
		try {
			iReqLength[m]=MPI.COMM_WORLD.iBcast(bbLength[m],4,MPI.BYTE,0);
			if(iReq[m]!=null) {
				iReq[m].waitFor();
			}
		} catch (MPIException e) {
			e.printStackTrace();
		}
		bb[m]=ByteBuffer.allocateDirect(b.length);
		bb[m].put(b);
		bb[m].clear();
		if(verbose){System.err.println("MPI:      Rank " + Shared.MPI_RANK + " broadcasting message of size " + bLength[0] + ".");}
		try {
			iReq[m]=MPI.COMM_WORLD.iBcast(bb[m],b.length,MPI.BYTE,0);
		} catch (MPIException e) {
			e.printStackTrace();
		}
	}
	
	private static ListNum<Read> blockingListenForListFromBroadcast(int fromRank){
		int[] bLength={0};
		try {
			MPI.COMM_WORLD.bcast(bLength,1,MPI.INT,fromRank);
		} catch (MPIException e) {
			e.printStackTrace();
		}
		byte[] b=new byte[bLength[0]];
		try {
			MPI.COMM_WORLD.bcast(b,bLength[0],MPI.BYTE,fromRank);
		} catch (MPIException e) {
			e.printStackTrace();
		}
		if(verbose){System.err.println("MPI:      Rank " + Shared.MPI_RANK + " received message of size " + bLength[0] + ".");}
		ListNum<Read> ln=(ListNum<Read>) deserialize(b);
		return ln;
	}

	private static ListNum<Read> blockingListenForListFromSend(int fromRank){
		Status s=null;
		int bLength=0;
		try {
			s=MPI.COMM_WORLD.probe(fromRank,50);
			bLength=s.getCount(MPI.BYTE);
		} catch (MPIException e) {
			e.printStackTrace();
		}
		byte[] b=new byte[bLength];
		try {
			MPI.COMM_WORLD.recv(b,bLength,MPI.BYTE,fromRank,50);
		} catch (MPIException e) {
			e.printStackTrace();
		}
		if(verbose){System.err.println("MPI:      Rank " + Shared.MPI_RANK + " received message of size " + bLength + ".");}
		ListNum<Read> ln=(ListNum<Read>) deserialize(b);
		return ln;
	}
	
	private static ListNum<Read> nonblockingListenForListFromBroadcast(int fromRank){
		int[] bLength={0};
		bbLength2=ByteBuffer.allocateDirect(4);
		Request req=null;
		try {
			req=MPI.COMM_WORLD.iBcast(bbLength2,4,MPI.BYTE,fromRank);
			req.waitFor();
		} catch (MPIException e) {
			e.printStackTrace();
		}
		bbLength2.clear();
		bLength[0]=bbLength2.getInt();
		byte[] b=new byte[bLength[0]];
		bb2=ByteBuffer.allocateDirect(bLength[0]);
		try {
			req=MPI.COMM_WORLD.iBcast(bb2,bLength[0],MPI.BYTE,fromRank);
			req.waitFor();
		} catch (MPIException e) {
			e.printStackTrace();
		}
		bb2.clear();
		bb2.get(b);
		if(verbose){System.err.println("MPI:      Rank " + Shared.MPI_RANK + " received message of size " + bLength[0] + ".");}
		ListNum<Read> ln=(ListNum<Read>) deserialize(b);
		return ln;
	}

	public static void broadcastBoolean(boolean b){
		boolean[] array={b};
		if(verbose){System.err.println("MPI:      Rank " + Shared.MPI_RANK + " broadcasting boolean of " + array[0] + ".");}
		try {
			MPI.COMM_WORLD.bcast(array,1,MPI.BOOLEAN,0);
		} catch (MPIException e) {
			e.printStackTrace();
		}
	}

	public static boolean listenForBooleanFromBroadcast(){
		boolean[] array={false};
		if(verbose){System.err.println("MPI:      Rank " + Shared.MPI_RANK + " listening for boolean.");}
		try {
			MPI.COMM_WORLD.bcast(array,1,MPI.BOOLEAN,0);
		} catch (MPIException e) {
			e.printStackTrace();
		}
		if(verbose){System.err.println("MPI:      Rank " + Shared.MPI_RANK + " received boolean of " + array[0] + ".");}
		return array[0];
	}

	private static byte[] serialize(Object obj) {
		ByteArrayOutputStream bos = null;
		ObjectOutputStream oos = null;
		try {
			bos = new ByteArrayOutputStream();
			oos = new ObjectOutputStream(bos);
			oos.writeObject(obj);
			oos.flush();
			oos.close();
			bos.close();
		} catch(IOException ioe) {
			ioe.printStackTrace();
		}
		return bos.toByteArray();
	}

	private static Object deserialize(byte[] bytes) {
		Object obj = null;
		ByteArrayInputStream bis = null;
		ObjectInputStream ois = null;
		try {
			bis = new ByteArrayInputStream(bytes);
			ois = new ObjectInputStream(bis);
			obj = ois.readObject();
			ois.close();
			bis.close();
		} catch(IOException ioe) {
			ioe.printStackTrace();
		} catch(ClassNotFoundException cnfe) {
			cnfe.printStackTrace();
		}
		return obj;
	}

	public static ListNum<Read> listenForListCris(int fromRank){
		if(Shared.MPI_KEEP_ALL){
			if(blocking){
				return blockingListenForListFromBroadcast(fromRank); //blocking broadcast
			}else{
				return nonblockingListenForListFromBroadcast(fromRank); //non-blocking broadcast
			}
		}else{
			return blockingListenForListFromSend(fromRank); //only need to use blocking receive for unicast
		}
	}

	public static ListNum<Read> listenForListCros(int fromRank){
		return blockingListenForListFromSend(fromRank); //only need to use blocking receive for unicast
	}

	private static boolean verbose=false;
	private static Request[] iReq;
	private static Request[] iReqLength;
	private static ByteBuffer[] bb;
	private static ByteBuffer[] bbLength;
	private static ByteBuffer bb2;
	private static ByteBuffer bbLength2;
	private static long n=-1;
	private static int msgsInFlight=2;
	private static boolean blocking=true;

}
