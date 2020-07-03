package assemble;

import java.io.File;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.BitSet;
import java.util.Collections;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

import jgi.BBMerge;
import kmer.AbstractKmerTableSet;

import ukmer.Kmer;
import ukmer.KmerTableSetU;

import stream.ByteBuilder;
import stream.ConcurrentReadInputStream;
import stream.ConcurrentReadOutputStream;
import stream.FastaReadInputStream;
import stream.Read;

import align2.IntList;
import align2.ListNum;
import align2.LongList;
import align2.ReadLengthComparator;
import align2.ReadStats;
import align2.Shared;
import align2.Tools;
import dna.AminoAcid;
import dna.Parser;
import dna.Timer;
import fileIO.ByteFile;
import fileIO.ByteStreamWriter;
import fileIO.ReadWrite;
import fileIO.FileFormat;
import fileIO.TextStreamWriter;


/**
 * Short-kmer assembler based on KmerCountExact.
 * @author Brian Bushnell
 * @date May 15, 2015
 *
 */
public abstract class Tadpole {
	
	/**
	 * Code entrance from the command line.
	 * @param args Command line arguments
	 */
	public static void main(String[] args){
		
		args=Parser.parseConfig(args);
		if(Parser.parseHelp(args, true)){
			printOptions();
			System.exit(0);
		}
		
		Timer t=new Timer(), t2=new Timer();
		t.start();
		t2.start();

		final Tadpole wog=makeTadpole(args, true);
		t2.stop();
		outstream.println("Initialization Time:      \t"+t2);
		
		///And run it
		wog.process(t);
	}
	
	public static Tadpole makeTadpole(String[] args, boolean setDefaults){
		final int k=preparseK(args);
		if(k<=31){
			return new Tadpole1(args, true);
		}else{
			return new Tadpole2(args, true);
		}
	}
	
	public static final int preparseK(String[] args){
		int k=31;
		for(int i=0; i<args.length; i++){
			final String arg=args[i];
			String[] split=arg.split("=");
			String a=split[0].toLowerCase();
			String b=split.length>1 ? split[1] : null;
			if("null".equalsIgnoreCase(b)){b=null;}
			while(a.charAt(0)=='-' && (a.indexOf('.')<0 || i>1 || !new File(a).exists())){a=a.substring(1);}
			
			if(a.equals("k")){
				k=Integer.parseInt(b);
			}
		}
		return Kmer.getMult(k)*Kmer.getK(k);
	}
	
	/**
	 * Display usage information.
	 */
	protected static final void printOptions(){
		outstream.println("Syntax:\nTODO");
	}
	
	/**
	 * Constructor.
	 * @param args Command line arguments
	 */
	public Tadpole(String[] args, boolean setDefaults){
		System.err.println("Executing "+getClass().getName()+" "+Arrays.toString(args)+"\n");
		kbig=preparseK(args);
		
		if(setDefaults){
			/* Set global defaults */
			ReadWrite.ZIPLEVEL=2;
			ReadWrite.USE_UNPIGZ=true;
			ReadWrite.USE_PIGZ=true;
			FastaReadInputStream.SPLIT_READS=false;
			ByteFile.FORCE_MODE_BF2=Shared.threads()>2;
			AbstractKmerTableSet.defaultMinprob=0.5;
		}
		
		/* Initialize local variables with defaults */
		Parser parser=new Parser();
		boolean ecc_=false, ecco_=false, setEcc_=false;
		boolean useOwnership_=false, setUseOwnership_=false;
		
		{
			boolean b=false;
			assert(b=true);
			EA=b;
		}
		
		/* Parse arguments */
		for(int i=0; i<args.length; i++){

			final String arg=args[i];
			String[] split=arg.split("=");
			String a=split[0].toLowerCase();
			String b=split.length>1 ? split[1] : null;
			if("null".equalsIgnoreCase(b)){b=null;}
			while(a.charAt(0)=='-' && (a.indexOf('.')<0 || i>1 || !new File(a).exists())){a=a.substring(1);}
			
			if(Parser.isJavaFlag(arg)){
				//jvm argument; do nothing
			}else if(a.equals("in") || a.equals("in1") || a.equals("ine") || a.equals("ine1")){
				in1.clear();
				if(b!=null){
					String[] s=b.split(",");
					for(String ss : s){
						in1.add(ss);
					}
				}
			}else if(a.equals("in2") || a.equals("ine2")){
				in2.clear();
				if(b!=null){
					String[] s=b.split(",");
					for(String ss : s){
						in2.add(ss);
					}
				}
			}else if(a.equals("out") || a.equals("out1") || a.equals("oute") || a.equals("oute1")){
				out1.clear();
				if(b!=null){
					String[] s=b.split(",");
					for(String ss : s){
						out1.add(ss);
					}
				}
			}else if(a.equals("out2") || a.equals("oute2")){
				out2.clear();
				if(b!=null){
					String[] s=b.split(",");
					for(String ss : s){
						out2.add(ss);
					}
				}
			}else if(a.equals("outd") || a.equals("outdiscard") || a.equals("outd1") || a.equals("outdiscard1")){
				outd1.clear();
				if(b!=null){
					String[] s=b.split(",");
					for(String ss : s){
						outd1.add(ss);
					}
				}
			}else if(a.equals("outd2") || a.equals("outdiscard2")){
				outd2.clear();
				if(b!=null){
					String[] s=b.split(",");
					for(String ss : s){
						outd2.add(ss);
					}
				}
			}else if(a.equals("outkmers") || a.equals("outk") || a.equals("dump")){
				outKmers=b;
			}else if(a.equals("mincounttodump")){
				minToDump=(int)Tools.parseKMG(b);
			}else if(a.equals("hist") || a.equals("khist")){
				outHist=b;
			}else if(a.equals("ihist") || a.equals("inserthistogram")){
				outInsert=b;
			}else if(a.equals("append") || a.equals("app")){
				append=ReadStats.append=Tools.parseBoolean(b);
			}else if(a.equals("overwrite") || a.equals("ow")){
				overwrite=Tools.parseBoolean(b);
			}else if(a.equals("mode")){
				if(Character.isDigit(b.charAt(0))){
					processingMode=(int)Tools.parseKMG(b);
				}else if(b.equalsIgnoreCase("contig")){
					processingMode=contigMode;
				}else if(b.equalsIgnoreCase("extend")){
					processingMode=extendMode;
				}else if(b.equalsIgnoreCase("correct") || b.equalsIgnoreCase("ecc")){
					processingMode=correctMode;
				}else if(b.equalsIgnoreCase("insert")){
					processingMode=insertMode;
				}else if(b.equalsIgnoreCase("discard")){
					processingMode=discardMode;
				}else{
					assert(false) : "Unknown mode "+b;
				}
			}else if(a.equals("ownership")){
				if("auto".equalsIgnoreCase(b)){
					setUseOwnership_=false;
				}else{
					useOwnership_=Tools.parseBoolean(b);
					setUseOwnership_=true;
				}
			}else if(a.equals("showstats") || a.equals("stats")){
				showStats=Tools.parseBoolean(b);
			}else if(a.equals("maxextension") || a.equals("maxe")){
				extendLeft=extendRight=(int)Tools.parseKMG(b);
			}else if(a.equals("extendright") || a.equals("er")){
				extendRight=(int)Tools.parseKMG(b);
			}else if(a.equals("extendleft") || a.equals("el")){
				extendLeft=(int)Tools.parseKMG(b);
			}else if(a.equals("minextension") || a.equals("mine")){
				minExtension=(int)Tools.parseKMG(b);
			}else if(a.equals("maxcontiglength") || a.equals("maxcontig") || a.equals("maxlength") || a.equals("maxlen") || a.equals("maxc")){
				maxContigLen=(int)Tools.parseKMG(b);
				if(maxContigLen<0){maxContigLen=1000000000;}
			}else if(a.equals("mincontiglength") || a.equals("mincontiglen") || a.equals("mincontig") || a.equals("minc")){
				minContigLen=(int)Tools.parseKMG(b);
			}else if(a.equals("mincoverage") || a.equals("mincov")){
				minCoverage=Float.parseFloat(b);
			}else if(a.equals("branchlower") || a.equals("branchlowerconst") || a.equals("blc")){
				branchLowerConst=(int)Tools.parseKMG(b);
			}else if(a.equals("branchmult2") || a.equals("bm2")){
				branchMult2=(int)Tools.parseKMG(b);
			}else if(a.equals("branchmult") || a.equals("branchmult1") || a.equals("bm1")){
				branchMult1=(int)Tools.parseKMG(b);
			}else if(a.equals("mincount") || a.equals("mincov") || a.equals("mindepth") || a.equals("min")){
				minCountSeed=minCountExtend=(int)Tools.parseKMG(b);
			}else if(a.equals("mindepthseed") || a.equals("mds") || a.equals("mincountseed") || a.equals("mcs")){
				minCountSeed=(int)Tools.parseKMG(b);
			}else if(a.equals("mindepthextend") || a.equals("mde") || a.equals("mincountextend") || a.equals("mce")){
				minCountExtend=(int)Tools.parseKMG(b);
			}else if(a.equals("mincountretain") || a.equals("mincr") || a.equals("mindepthretain") || a.equals("mindr")){
				kmerRangeMin=(int)Tools.parseKMG(b);
			}else if(a.equals("maxcountretain") || a.equals("maxcr") || a.equals("maxdepthretain") || a.equals("maxdr")){
				kmerRangeMax=(int)Tools.parseKMG(b);
			}else if(a.equals("contigpasses")){
				contigPasses=(int)Tools.parseKMG(b);
			}else if(a.equals("contigpassmult")){
				contigPassMult=Double.parseDouble(b);
				assert(contigPassMult>=1) : "contigPassMult must be at least 1.";
			}else if(a.equals("threads") || a.equals("t")){
				Shared.setThreads(b);
			}else if(a.equals("showspeed") || a.equals("ss")){
				showSpeed=Tools.parseBoolean(b);
			}else if(a.equals("verbose")){
//				assert(false) : "Verbose flag is currently static final; must be recompiled to change.";
				verbose=Tools.parseBoolean(b);
			}else if(a.equals("verbose2")){
//				assert(false) : "Verbose flag is currently static final; must be recompiled to change.";
				verbose2=Tools.parseBoolean(b);
			}else if(a.equals("ordered")){
				ordered=Tools.parseBoolean(b);
			}else if(a.equals("reads") || a.startsWith("maxreads")){
				maxReads=Tools.parseKMG(b);
			}else if(a.equals("histcolumns")){
				histColumns=(int)Tools.parseKMG(b);
			}else if(a.equals("histmax")){
				histMax=(int)Tools.parseKMG(b);
			}else if(a.equals("histheader")){
				histHeader=Tools.parseBoolean(b);
			}else if(a.equals("nzo") || a.equals("nonzeroonly")){
				histZeros=!Tools.parseBoolean(b);
			}else if(a.equals("ilb") || a.equals("ignoreleftbranches") || a.equals("ignoreleftjunctions") || a.equals("ibb") || a.equals("ignorebackbranches")){
				extendThroughLeftJunctions=Tools.parseBoolean(b);
			}else if(a.equals("ibo") || a.equals("ignorebadowner")){
				IGNORE_BAD_OWNER=Tools.parseBoolean(b);
			}
			
			//Shaver
			else if(a.equals("shave") || a.equals("removedeadends")){
				if(b==null || Character.isLetter(b.charAt(0))){
					removeDeadEnds=Tools.parseBoolean(b);
				}else{
					maxShaveDepth=Integer.parseInt(b);
					removeDeadEnds=(maxShaveDepth>0);
				}
			}else if(a.equals("rinse") || a.equals("shampoo") || a.equals("removebubbles")){
				removeBubbles=Tools.parseBoolean(b);
			}else if(a.equals("maxshavedepth") || a.equals("shavedepth") || a.equals("msd")){
				maxShaveDepth=Integer.parseInt(b);
			}else if(a.equals("shavediscardlength") || a.equals("shavelength") || a.equals("discardlength") || a.equals("sdl")){
				shaveDiscardLen=Integer.parseInt(b);
			}else if(a.equals("shaveexploredistance") || a.equals("shaveexploredist") || a.equals("exploredist") || a.equals("sed")){
				shaveExploreDist=Integer.parseInt(b);
			}else if(a.equals("printeventcounts")){
				Shaver.printEventCounts=Tools.parseBoolean(b);
			}
			
			
			//Junk removal
			else if(a.equals("tossjunk")){
				tossJunk=Tools.parseBoolean(b);
			}else if(a.equals("tossdepth") || a.equals("discarddepth")){
				discardLowDepthReads=Integer.parseInt(b);
			}
			
			
			//Error Correction
			else if(a.equals("ecctail") || a.equals("eccright") || a.equals("tail")){
				ECC_TAIL=Tools.parseBoolean(b);
			}else if(a.equals("pincer") || a.equals("eccpincer")){
				ECC_PINCER=Tools.parseBoolean(b);
			}else if(a.equals("eccall") || a.equals("eccfull") || a.equals("ecccomplete") || a.equals("aecc") || a.equals("aec") || a.equals("aggressive")){
				ECC_ALL=Tools.parseBoolean(b);
			}else if(a.equals("ecc")){
				ecc_=Tools.parseBoolean(b);
				setEcc_=true;
			}else if(a.equals("ecco")){
				ecco_=Tools.parseBoolean(b);
			}else if(a.equals("em1") || a.equals("errormult1")){
				errorMult1=Float.parseFloat(b);
			}else if(a.equals("em2") || a.equals("errormult2")){
				errorMult2=Float.parseFloat(b);
			}else if(a.equals("elc") || a.equals("errorlowerconst")){
				errorLowerConst=Integer.parseInt(b);
			}else if(a.equals("mcc") || a.equals("mincountcorrect")){
				minCountCorrect=Integer.parseInt(b);
			}else if(a.equals("psc") || a.equals("pathsimilarityconstant")){
				pathSimilarityConstant=Integer.parseInt(b);
			}else if(a.equals("psf") || a.equals("pathsimilarityfraction")){
				pathSimilarityFraction=Float.parseFloat(b);
			}else if(a.equals("eep") || a.equals("errorextensionpincer")){
				errorExtensionPincer=Integer.parseInt(b);
			}else if(a.equals("eet") || a.equals("errorextensiontail")){
				errorExtensionTail=Integer.parseInt(b);
			}else if(a.equals("mbb") || a.equals("markbad") || a.equals("markbadbases")){
				if(b==null){b="1";}
				MARK_BAD_BASES=Integer.parseInt(b);
			}else if(a.equals("mdo") || a.equals("markdeltaonly")){
				MARK_DELTA_ONLY=Tools.parseBoolean(b);
			}
			
			//Trimming
			else if(a.equals("trim") || a.equals("trimends")){
				if(b==null || Character.isLetter(b.charAt(0))){
					trimEnds=Tools.parseBoolean(b) ? -1 : 0;
				}else{
					trimEnds=Integer.parseInt(b);
				}
				trimEnds=Tools.max(trimEnds, 0);
			}
			
			else if(Parser.parseCommonStatic(arg, a, b)){
				//do nothing
			}else if(Parser.parseZip(arg, a, b)){
				//do nothing
			}else if(Parser.parseQuality(arg, a, b)){
				//do nothing
			}else if(Parser.parseFasta(arg, a, b)){
				//do nothing
			}else if(parser.parseInterleaved(arg, a, b)){
				//do nothing
			}else if(parser.parseTrim(arg, a, b)){
				//do nothing
			}
			
			else if(KmerTableSetU.isValidArgument(a)){
				//Do nothing
			}else{
				throw new RuntimeException("Unknown parameter "+args[i]);
			}
		}
		
		if(trimEnds==-1){
			trimEnds=kbig/2;
		}
		
		if(verbose){
			assert(false) : "Verbose is disabled.";
//			AbstractKmerTableU.verbose=true;
		}
		THREADS=Shared.threads();
		
		assert(kmerRangeMax>=kmerRangeMin) : "kmerRangeMax must be at least kmerRangeMin: "+kmerRangeMax+", "+kmerRangeMin;
		
		if(processingMode<0){//unset
			if(ecc_){
				processingMode=correctMode;
				System.err.println("Switching to correct mode because ecc=t.");
			}else if(extendLeft>0 || extendRight>0){
				processingMode=extendMode;
				System.err.println("Switching to extend mode because an extend flag was set.");
			}else if(tossJunk || discardLowDepthReads>0){
				processingMode=discardMode;
				System.err.println("Switching to discard mode because a discard flag was set.");
			}else{
				processingMode=contigMode;
				//System.err.println("Operating in contig mode.");
			}
		}
		
		if(processingMode==extendMode || processingMode==correctMode || processingMode==discardMode){
			
//			{//Use in and out if ine and oute are not specified, in this mode.
//				if(ine1.isEmpty() && ine2.isEmpty()){
//					ine1.addAll(in1);
//					ine2.addAll(in2);
//				}
//				if(oute1.isEmpty() && oute2.isEmpty() && outContigs!=null){
//					oute1.add(outContigs);
//				}
//			}
			
			if(processingMode==extendMode){
				if(extendLeft==-1){extendLeft=100;}
				if(extendRight==-1){extendRight=100;}
			}else if(processingMode==correctMode){
				extendLeft=extendRight=0;
				if(!setEcc_){ecc_=true;}
			}else if(processingMode==discardMode){
				extendLeft=extendRight=0;
				if(!setEcc_){ecc_=false;}
			}
		}
		
		{//Process parser fields
			Parser.parseQuality("","","");
			Parser.processQuality();
		}
		
		if(setUseOwnership_){
			useOwnership=useOwnership_;
		}else{
			useOwnership=(processingMode==contigMode || removeBubbles || removeDeadEnds);
		}
		
		final int extraBytesPerKmer;
		{
			int x=0;
			if(useOwnership){x+=4;}
			if(processingMode==correctMode || processingMode==discardMode){}
			else if(processingMode==contigMode || processingMode==extendMode){x+=1;}
			extraBytesPerKmer=x;
		}
		
		/* Set final variables; post-process and validate argument combinations */
		
		ecc=ecc_;
		ecco=ecco_;
		
		/* Adjust I/O settings and filenames */
		
		assert(FastaReadInputStream.settingsOK());
		
		for(int i=0; i<in1.size(); i++){
			String s=in1.get(i);
			if(s!=null && s.contains("#") && !new File(s).exists()){
				int pound=s.lastIndexOf('#');
				String a=s.substring(0, pound);
				String b=s.substring(pound+1);
				in1.set(i, a+1+b);
				in2.add(a+2+b);
			}
		}
		
		for(int i=0; i<out1.size(); i++){
			String s=out1.get(i);
			if(s!=null && s.contains("#")){
				int pound=s.lastIndexOf('#');
				String a=s.substring(0, pound);
				String b=s.substring(pound+1);
				out1.set(i, a+1+b);
				out2.add(a+2+b);
			}
		}
		
		for(int i=0; i<outd1.size(); i++){
			String s=outd1.get(i);
			if(s!=null && s.contains("#")){
				int pound=s.lastIndexOf('#');
				String a=s.substring(0, pound);
				String b=s.substring(pound+1);
				outd1.set(i, a+1+b);
				outd2.add(a+2+b);
			}
		}

		nextTable=new AtomicInteger[contigPasses];
		nextVictims=new AtomicInteger[contigPasses];
		for(int i=0; i<contigPasses; i++){
			nextTable[i]=new AtomicInteger(0);
			nextVictims[i]=new AtomicInteger(0);
		}

		if(!Tools.testOutputFiles(overwrite, append, false, outKmers, outHist)){
			throw new RuntimeException("\nCan't write to some output files; overwrite="+overwrite+"\n");
		}
		if(!Tools.testOutputFiles(overwrite, append, false, out1, out2)){
			throw new RuntimeException("\nCan't write to some output files; overwrite="+overwrite+"\n");
		}
		if(!Tools.testInputFiles(true, true, in1, in2)){
			throw new RuntimeException("\nCan't read to some input files.\n");
		}
		assert(THREADS>0);
		outstream.println("Using "+THREADS+" threads.");
	}

	
	/*--------------------------------------------------------------*/
	/*----------------         Outer Methods        ----------------*/
	/*--------------------------------------------------------------*/
	
	
	public final void process(Timer t){
		
		/* Check for output file collisions */
		Tools.testOutputFiles(overwrite, append, false, outKmers, outHist);
		
		/* Count kmers */
		process2(processingMode);
		
		if(THREADS>1 && outHist!=null && outKmers!=null){
			Timer tout=new Timer();
			tout.start();
			Thread a=new DumpKmersThread();
			Thread b=new MakeKhistThread();
			a.start();
			b.start();
			while(a.getState()!=Thread.State.TERMINATED){
				try {
					a.join();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
			while(b.getState()!=Thread.State.TERMINATED){
				try {
					b.join();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
			tout.stop();
			outstream.println("Write Time:                 \t"+tout);
		}else{
			if(outHist!=null){
				makeKhist();
			}
			if(outKmers!=null){
				dumpKmersAsText();
			}
		}
		
		clearData();
		
		/* Stop timer and calculate speed statistics */
		t.stop();
		
		
		if(showSpeed){
			double rpnano=readsIn/(double)(t.elapsed);
			double bpnano=basesIn/(double)(t.elapsed);

			//Format with k or m suffixes
			String rpstring=(readsIn<100000 ? ""+readsIn : readsIn<100000000 ? (readsIn/1000)+"k" : (readsIn/1000000)+"m");
			String bpstring=(basesIn<100000 ? ""+basesIn : basesIn<100000000 ? (basesIn/1000)+"k" : (basesIn/1000000)+"m");

			while(rpstring.length()<8){rpstring=" "+rpstring;}
			while(bpstring.length()<8){bpstring=" "+bpstring;}
			
			outstream.println("\nTotal Time:               \t"+t);
			
			if(processingMode==extendMode || processingMode==correctMode || processingMode==discardMode){
				outstream.println("\nReads Processed:    "+rpstring+" \t"+String.format("%.2fk reads/sec", rpnano*1000000));
				outstream.println("Bases Processed:    "+bpstring+" \t"+String.format("%.2fm bases/sec", bpnano*1000));
			}
		}
		
		{
			String outContigs=out1.isEmpty() ? null : out1.get(0);
			if(showStats && outContigs!=null && processingMode==contigMode && FileFormat.isFasta(ReadWrite.rawExtension(outContigs))){
				outstream.println();
				jgi.AssemblyStats2.main(new String[] {"in="+outContigs});
			}
		}
		
		/* Throw an exception if errors were detected */
		if(errorState){
			throw new RuntimeException(getClass().getSimpleName()+" terminated in an error state; the output may be corrupt.");
		}
	}
	
	abstract void makeKhist();
	abstract void dumpKmersAsText();
	public abstract long loadKmers(Timer t);
	
	public final void clearData(){
		allContigs=null;
		tables().clear();
	}
	
	public final void process2(int mode){
		
		/* Start phase timer */
		Timer t=new Timer();
		
		/* Fill tables with kmers */
		outstream.println("\nLoading kmers.\n");
		loadKmers(t);
		
		t.stop();
//		outstream.println("Input:                      \t"+tables.readsIn+" reads \t\t"+tables.basesIn+" bases.");
//		outstream.println("Unique Kmers:               \t"+tables.kmersLoaded);
//		outstream.println("Load Time:                  \t"+t);
		
		
		t.start();
		
		shaveAndRinse(t, removeDeadEnds, removeBubbles, true);
		
		if(kmerRangeMin>1 || kmerRangeMax<Integer.MAX_VALUE){
			AbstractRemoveThread.process(THREADS, kmerRangeMin, kmerRangeMax, tables(), true);
		}
		
		if(mode==extendMode || mode==correctMode || mode==discardMode){
			outstream.println("\nExtending/error-correcting/discarding.\n");
			
			final boolean vic=Read.VALIDATE_IN_CONSTRUCTOR;
			Read.VALIDATE_IN_CONSTRUCTOR=false;
			extendReads();
			Read.VALIDATE_IN_CONSTRUCTOR=vic;
			
			if(DISPLAY_PROGRESS){
				outstream.println("\nAfter extending reads:");
				Shared.printMemory();
				outstream.println();
			}
			
			t.stop();

			outstream.println("Input:                      \t"+readsIn+" reads \t\t"+basesIn+" bases.");
			outstream.println("Output:                     \t"+readsIn+" reads \t\t"+(basesIn+basesExtended)+" bases.");
			if(extendLeft>0 || extendRight>0){
				outstream.println("Bases extended:             \t"+basesExtended);
				outstream.println("Reads extended:             \t"+readsExtended+String.format(" \t(%.2f%%)", readsExtended*100.0/readsIn));
			}
			if(ecc){
				long partial=(readsCorrected-readsFullyCorrected);
				outstream.println("Errors detected:            \t"+basesDetected);
				outstream.println("Errors corrected:           \t"+(basesCorrectedTail+basesCorrectedPincer)+" \t("+basesCorrectedPincer+" pincer, "+basesCorrectedTail+" tail)");
				outstream.println("Reads with errors detected: \t"+readsDetected+String.format(" \t(%.2f%%)", readsDetected*100.0/readsIn));
				outstream.println("Reads fully corrected:      \t"+readsCorrected+String.format(" \t(%.2f%% of detected)", readsFullyCorrected*100.0/readsDetected));
				outstream.println("Reads partly corrected:     \t"+partial+String.format(" \t(%.2f%% of detected)", partial*100.0/readsDetected));
			}
			if(tossJunk || discardLowDepthReads>0){
				outstream.println("Reads discarded:            \t"+readsDiscarded+String.format(" \t(%.2f%%)", readsDiscarded*100.0/readsIn));
				outstream.println("Bases discarded:            \t"+basesDiscarded+String.format(" \t(%.2f%%)", basesDiscarded*100.0/basesIn));
			}
			if(MARK_BAD_BASES>0){
				outstream.println("Reads marked:               \t"+readsMarked+String.format(" \t(%.2f%%)", readsMarked*100.0/readsIn));
				outstream.println("Bases marked:               \t"+basesMarked+String.format(" \t(%.2f%%)", basesMarked*100.0/basesIn));
			}
			
			outstream.println("Extend/error-correct time:  \t"+t);
		}else{
			/* Build contigs */
			outstream.println("\nBuilding contigs.\n");
			buildContigs(mode);
			
			if(DISPLAY_PROGRESS){
				outstream.println("\nAfter building contigs:");
				Shared.printMemory();
				outstream.println();
			}
			
			t.stop();
			
			if(readsIn>0){outstream.println("Input:                      \t"+readsIn+" reads \t\t"+basesIn+" bases.");}
			outstream.println("Bases generated:            \t"+basesBuilt);
			outstream.println("Contigs generated:          \t"+contigsBuilt);
			outstream.println("Longest contig:             \t"+longestContig);
			outstream.println("Contig-building time:       \t"+t);
		}
	}
	
	
	/*--------------------------------------------------------------*/
	/*----------------         Inner Methods        ----------------*/
	/*--------------------------------------------------------------*/
	
	public final long shaveAndRinse(Timer t, boolean shave, boolean rinse, boolean print){
		long removed=0;
		if(shave || rinse){
			
			if(print){
				if(rinse && shave){
					outstream.println("\nRemoving dead ends and error bubbles.");
				}else if(shave){
					outstream.println("\nRemoving dead ends.");
				}else if(rinse){
					outstream.println("\nRemoving error bubbles.");
				}
			}

			removed=shave(shave, rinse);
			t.stop();

			if(print){
				outstream.println("Kmers removed:              \t"+removed);
				outstream.println("Removal time:               \t"+t);
			}

			t.start();
		}
		return removed;
	}
	
	abstract long shave(boolean shave, boolean rinse);
	abstract void initializeOwnership();
	
	/**
	 * Build contigs.
	 */
	private final void buildContigs(final int mode){
		
		if(mode==contigMode){
			allContigs=new ArrayList<Read>();
			allInserts=null;
			
			if(useOwnership){
				initializeOwnership();
			}
			
		}else if(mode==insertMode){
			allContigs=null;
			allInserts=new LongList();
		}else if(mode==extendMode){
			throw new RuntimeException("extendMode: TODO");
		}else{
			throw new RuntimeException("Unknown mode "+mode);
		}
		
		/* Create read input stream */
		final ConcurrentReadInputStream[] crisa=(mode==contigMode ? null : makeCrisArray(in1, in2));
		
		/* Create ProcessThreads */
		ArrayList<AbstractBuildThread> alpt=new ArrayList<AbstractBuildThread>(THREADS);
		for(int i=0; i<THREADS; i++){alpt.add(makeBuildThread(i, mode, crisa));}
		for(AbstractBuildThread pt : alpt){pt.start();}
		
		/* Wait for threads to die, and gather statistics */
		for(AbstractBuildThread pt : alpt){
			while(pt.getState()!=Thread.State.TERMINATED){
				try {
					pt.join();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
			for(Read contig : pt.contigs){
				allContigs.add(contig);
				contigsBuilt++;
				basesBuilt+=contig.length();
				longestContig=Tools.max(longestContig, contig.length());
			}
			if(allInserts!=null){
				allInserts.add(pt.insertSizes);
			}
			
			readsIn+=pt.readsInT;
			basesIn+=pt.basesInT;
			lowqReads+=pt.lowqReadsT;
			lowqBases+=pt.lowqBasesT;
		}
		
		/* Shut down I/O streams; capture error status */
		if(crisa!=null){
			for(ConcurrentReadInputStream cris : crisa){
				errorState|=ReadWrite.closeStreams(cris);
			}
		}
		
		if(outInsert!=null){
			FileFormat ff=FileFormat.testOutput(outInsert, FileFormat.TEXT, 0, 0, true, overwrite, append, false);
			TextStreamWriter tsw=new TextStreamWriter(ff);
			tsw.start();
			for(int i=0; i<allInserts.size; i++){
				long count=allInserts.get(i);
				if(count>0 || histZeros){
					tsw.print(i+"\t"+count+"\n");
				}
			}
			errorState|=tsw.poisonAndWait();
		}
		
		String outContigs=out1.isEmpty() ? null : out1.get(0);
		if(outContigs!=null){
			FileFormat ff=FileFormat.testOutput(outContigs, FileFormat.FA, 0, 0, true, overwrite, append, false);
//			ConcurrentReadOutputStream ros=ConcurrentReadOutputStream.getStream(ff, null, null, null, 4, null, false);
//			ros.start();
			ByteStreamWriter bsw=new ByteStreamWriter(ff);
			bsw.start();
			if(allContigs!=null){
//				Collections.sort(allContigs, ReadComparatorID.comparator);
				Collections.sort(allContigs, ReadLengthComparator.comparator);
				for(int i=0; i<allContigs.size(); i++){
					Read r=allContigs.get(i);
					bsw.println(r);
				}
			}
			errorState|=bsw.poisonAndWait();
		}
	}
	
	
	/**
	 * @param i
	 * @param mode
	 * @param crisa
	 * @return
	 */
	abstract AbstractBuildThread makeBuildThread(int i, int mode, ConcurrentReadInputStream[] crisa);

	/**
	 * Extend reads.
	 */
	private final void extendReads(){

		/* Create read input stream */
		final ConcurrentReadInputStream[] crisa=makeCrisArray(in1, in2);

		/* Create read input stream */
		final ConcurrentReadOutputStream[] rosa=makeCrosArray(out1, out2);

		/* Create read input stream */
		final ConcurrentReadOutputStream[] rosda=makeCrosArray(outd1, outd2);
		
		/* Create ProcessThreads */
		ArrayList<ExtendThread> alpt=new ArrayList<ExtendThread>(THREADS);
		for(int i=0; i<THREADS; i++){alpt.add(new ExtendThread(i, crisa, rosa, rosda));}
		for(ExtendThread pt : alpt){pt.start();}
		
		/* Wait for threads to die, and gather statistics */
		for(ExtendThread pt : alpt){
			while(pt.getState()!=Thread.State.TERMINATED){
				try {
					pt.join();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
			
			readsIn+=pt.readsInT;
			basesIn+=pt.basesInT;
			lowqReads+=pt.lowqReadsT;
			lowqBases+=pt.lowqBasesT;
			readsExtended+=pt.readsExtendedT;
			basesExtended+=pt.basesExtendedT;
			readsCorrected+=pt.readsCorrectedT;
			basesCorrectedPincer+=pt.basesCorrectedPincerT;
			basesCorrectedTail+=pt.basesCorrectedTailT;
			readsFullyCorrected+=pt.readsFullyCorrectedT;
			readsDetected+=pt.readsDetectedT;
			basesDetected+=pt.basesDetectedT;
			readsMarked+=pt.readsMarkedT;
			basesMarked+=pt.basesMarkedT;
			readsDiscarded+=pt.readsDiscardedT;
			basesDiscarded+=pt.basesDiscardedT;
		}
		
		/* Shut down I/O streams; capture error status */
		for(ConcurrentReadInputStream cris : crisa){
			errorState|=ReadWrite.closeStreams(cris);
		}
		/* Shut down I/O streams; capture error status */
		if(rosa!=null){
			for(ConcurrentReadOutputStream ros : rosa){
				errorState|=ReadWrite.closeStream(ros);
			}
		}
		if(rosda!=null){
			for(ConcurrentReadOutputStream ros : rosda){
				errorState|=ReadWrite.closeStream(ros);
			}
		}
	}
	
	private final ConcurrentReadInputStream[] makeCrisArray(ArrayList<String> list1, ArrayList<String> list2){
		final ConcurrentReadInputStream[] array;

		array=new ConcurrentReadInputStream[list1.size()];
		for(int i=0; i<list1.size(); i++){
			String a=list1.get(i);
			String b=(list2.size()>i ? list2.get(i): null);
			if(verbose){System.err.println("Creating cris for "+a);}

			final ConcurrentReadInputStream cris;
			{
				FileFormat ff1=FileFormat.testInput(a, FileFormat.FASTA, null, true, true);
				FileFormat ff2=(b==null ? null : FileFormat.testInput(b, FileFormat.FASTA, null, true, true));
				cris=ConcurrentReadInputStream.getReadInputStream(maxReads, false, ff1, ff2);
			}
			array[i]=cris;
		}
		return array;
	}
	
	private final ConcurrentReadOutputStream[] makeCrosArray(ArrayList<String> list1, ArrayList<String> list2){
		final ConcurrentReadOutputStream[] array;

		array=new ConcurrentReadOutputStream[list1.size()];
		for(int i=0; i<list1.size(); i++){
			String a=list1.get(i);
			String b=(list2.size()>i ? list2.get(i): null);
			if(verbose){System.err.println("Creating cris for "+a);}

			final ConcurrentReadOutputStream cris;
			{
				final int buff=(!ordered ? 12 : Tools.max(32, 2*Shared.threads()));
				FileFormat ff1=FileFormat.testOutput(a, FileFormat.FASTQ, null, true, overwrite, append, ordered);
				FileFormat ff2=(b==null ? null : FileFormat.testOutput(b, FileFormat.FASTQ, null, true, overwrite, append, ordered));
//				assert(false) : list1+", "+list2;
				cris=ConcurrentReadOutputStream.getStream(ff1, ff2, null, null, buff, null, false);
			}
			array[i]=cris;
		}
		return array;
	}
	
	/*--------------------------------------------------------------*/
	/*----------------         Inner Classes        ----------------*/
	/*--------------------------------------------------------------*/
	
	/*--------------------------------------------------------------*/
	/*----------------         ExtendThread         ----------------*/
	/*--------------------------------------------------------------*/

	/**
	 * Extends reads. 
	 */
	private final class ExtendThread extends Thread{
		
		/**
		 * Constructor
		 * @param cris_ Read input stream
		 */
		public ExtendThread(int id_, ConcurrentReadInputStream[] crisa_, ConcurrentReadOutputStream[] rosa_, ConcurrentReadOutputStream[] rosda_){
			id=id_;
			crisa=crisa_;
			rosa=rosa_;
			rosda=rosda_;
			leftCounts=extendThroughLeftJunctions ? null : new int[4];
		}
		
		@Override
		public void run(){
			initializeThreadLocals();
			for(int i=0; i<crisa.length; i++){
				ConcurrentReadInputStream cris=crisa[i];
				ConcurrentReadOutputStream ros=(rosa!=null && rosa.length>i ? rosa[i] : null);
				ConcurrentReadOutputStream rosd=(rosda!=null && rosda.length>i ? rosda[i] : null);
				synchronized(crisa){
					if(!cris.started()){
						cris.start();
					}
				}
				if(ros!=null){
					synchronized(rosa){
						if(!ros.started()){
							ros.start();
						}
					}
				}
				if(rosd!=null){
					synchronized(rosda){
						if(!rosd.started()){
							rosd.start();
						}
					}
				}
				run(cris, ros, rosd);
			}
		}
		
		private void run(ConcurrentReadInputStream cris, ConcurrentReadOutputStream ros, ConcurrentReadOutputStream rosd){
			
			ListNum<Read> ln=cris.nextList();
			ArrayList<Read> reads=(ln!=null ? ln.list : null);
			
			//While there are more reads lists...
			while(reads!=null && reads.size()>0){

				final ArrayList<Read> listOut=new ArrayList<Read>(reads.size());
				final ArrayList<Read> listOutD=(rosd==null ? null : new ArrayList<Read>(reads.size()));
				
				//For each read (or pair) in the list...
				for(int i=0; i<reads.size(); i++){
					final Read r1=reads.get(i);
					final Read r2=r1.mate;
					
					processReadPair(r1, r2);
					if(r1.discarded() && (r2==null || r2.discarded())){
						readsDiscardedT+=1+r1.mateCount();
						basesDiscardedT+=r1.length()+r1.mateLength();
						if(listOutD!=null){listOutD.add(r1);}
					}else{
						listOut.add(r1);
					}
				}
				if(ros!=null){ros.add(listOut, ln.id);}
				if(rosd!=null){rosd.add(listOutD, ln.id);}
				
				//Fetch a new read list
				cris.returnList(ln.id, ln.list.isEmpty());
				ln=cris.nextList();
				reads=(ln!=null ? ln.list : null);
			}
			cris.returnList(ln.id, ln.list.isEmpty());
		}
		
		private void processReadPair(Read r1, Read r2){
			if(verbose){System.err.println("Considering read "+r1.id+" "+new String(r1.bases));}
			
			readsInT++;
			basesInT+=r1.length();
			if(r2!=null){
				readsInT++;
				basesInT+=r2.length();
			}
			
			if(ecco && r1!=null && r2!=null && !r1.discarded() && !r2.discarded()){BBMerge.findOverlapStrict(r1, r2, true);}
			
			processRead(r1);
			processRead(r2);
		}
		
		private void processRead(Read r){
			if(r==null){return;}
			if(!r.validated()){r.validate(true);}
			if(r.discarded()){
				lowqBasesT+=r.length();
				lowqReadsT++;
				return;
			}
			if(ecc || MARK_BAD_BASES>0){
				final int corrected=errorCorrect(r, leftCounts, rightCounts, kmerList, countList, builderT, detectedArrayT, bitsetT, kmerT);
				final int detected=detectedArrayT[0];
				final int correctedPincer=detectedArrayT[1];
				final int correctedTail=detectedArrayT[2];
				final int marked=detectedArrayT[3];
				assert(corrected==correctedPincer+correctedTail) : corrected+", "+Arrays.toString(detectedArrayT);
				if(detected>0){
					readsDetectedT++;
					basesDetectedT+=detected;
					if(corrected>0){
						readsCorrectedT++;
						basesCorrectedPincerT+=correctedPincer;
						basesCorrectedTailT+=correctedTail;
					}
					if(corrected==detected){
						readsFullyCorrectedT++;
					}
				}
				if(marked>0){
					readsMarkedT++;
					basesMarkedT+=marked;
				}
			}
			
			if(tossJunk && isJunk(r, rightCounts, kmerT)){
				r.setDiscarded(true);
				return;
			}
			
			if(discardLowDepthReads>0 && hasLowCountKmers(r, discardLowDepthReads, kmerT)){
				r.setDiscarded(true);
				if(r.mate!=null){r.mate.setDiscarded(true);}
			}
			
			int extension=0;
			if(extendRight>0){
				extension+=extendRead(r, builderT, leftCounts, rightCounts, extendRight, kmerT);
			}
			if(extendLeft>0){
				r.reverseComplement();
				extension+=extendRead(r, builderT, leftCounts, rightCounts, extendLeft, kmerT);
				r.reverseComplement();
			}
			basesExtendedT+=extension;
			readsExtendedT+=(extension>0 ? 1 : 0);
		}
		
		/*--------------------------------------------------------------*/
		
		/** Input read stream */
		private final ConcurrentReadInputStream[] crisa;
		private final ConcurrentReadOutputStream[] rosa;
		private final ConcurrentReadOutputStream[] rosda;

		private final int[] leftCounts;
		private final int[] rightCounts=new int[4];
		private final int[] detectedArrayT=new int[4];
		private final ByteBuilder builderT=new ByteBuilder();
		private final Kmer kmerT=new Kmer(kbig);
		private final BitSet bitsetT=new BitSet(300);
		private final LongList kmerList=new LongList();
		private final IntList countList=new IntList();
		
		private long readsInT=0;
		private long basesInT=0;
		private long lowqReadsT=0;
		private long lowqBasesT=0;
		private long readsExtendedT=0;
		private long basesExtendedT=0;
		private long readsCorrectedT=0;
		private long basesCorrectedTailT=0;
		private long basesCorrectedPincerT=0;
		private long readsFullyCorrectedT=0;
		private long readsDetectedT=0;
		private long basesDetectedT=0;
		private long readsMarkedT=0;
		private long basesMarkedT=0;
		private long readsDiscardedT=0;
		private long basesDiscardedT=0;
		
		private final int id;
		
	}
	
	
	/*--------------------------------------------------------------*/
	/*----------------       Extension Methods      ----------------*/
	/*--------------------------------------------------------------*/

	public abstract int extendRead(Read r, ByteBuilder bb, int[] leftCounts, int[] rightCounts, int distance);
	public abstract int extendRead(Read r, ByteBuilder bb, int[] leftCounts, int[] rightCounts, int distance, final Kmer kmer);
//	{
//		throw new RuntimeException("Must be overridden.");
//	}
	
	/**
	 * Extend these bases to the right by at most 'distance'.
	 * Stops at right junctions only.
	 * Does not claim ownership.
	 */
	public abstract int extendToRight2(final ByteBuilder bb, final int[] leftCounts, final int[] rightCounts, final int distance, boolean includeJunctionBase);
	
	/**
	 * Extend these bases to the right by at most 'distance'.
	 * Stops at right junctions only.
	 * Does not claim ownership.
	 */
	public int extendToRight2(final ByteBuilder bb, final int[] leftCounts, final int[] rightCounts, final int distance, boolean includeJunctionBase, Kmer kmer){
		throw new RuntimeException("Must be overridden.");
	}
	
	
	/*--------------------------------------------------------------*/
	/*----------------        Junk Detection        ----------------*/
	/*--------------------------------------------------------------*/
	
	/** Test a read to see if it could possibly assemble. */
	public abstract boolean isJunk(Read r);
	
	public abstract boolean isJunk(Read r, final int[] localLeftCounts, Kmer kmer);

	public abstract boolean hasLowCountKmers(Read r, int minCount);
	
	public abstract boolean hasLowCountKmers(Read r, int minCount, Kmer kmer);
	
	/*--------------------------------------------------------------*/
	/*----------------       Error Correction       ----------------*/
	/*--------------------------------------------------------------*/
	
	public abstract int errorCorrect(Read r);
	
	public abstract int errorCorrect(Read r, final int[] leftCounts, final int[] rightCounts, LongList kmers, IntList counts, 
			final ByteBuilder bb, final int[] detectedArray, final BitSet bs, Kmer kmer);
	
	/** Changes to N any base covered strictly by kmers with count below minCount */
	public final int markBadBases(final byte[] bases, final byte[] quals, final IntList counts, final BitSet bs, final int minCount, boolean deltaOnly){
		if(counts.size<1){return 0;}
		
		bs.clear();
		assert(counts.size==bases.length-kbig+1) : counts.size+", "+bases.length;
		
//		boolean flag=true;
		for(int i=0; i<counts.size;){
			final int count=counts.get(i);
			if(count>=minCount){
				bs.set(i, i+kbig);
				i+=kbig;
			}else{
//				flag=false;
				i++;
			}
		}
		{//Last cycle
			final int i=counts.size-1;
			final int count=counts.get(i);
			if(count>=minCount){
				bs.set(i, i+kbig);
			}	
		}
		
		final int card=bs.cardinality();
		final int toMark=bases.length-card;
		int marked=0;
		assert(card<=bases.length);
		
		int consecutiveBad=0;
		for(int i=0; i<bases.length; i++){
			if(bs.get(i)){
				consecutiveBad=0;
			}else{
				consecutiveBad++;
				boolean mark=(bases[i]!='N');
				if(mark && deltaOnly){
					mark=(consecutiveBad>=kbig) || bs.get(i+1) || (i>0 && bs.get(i-1));
				}
				if(mark){
					marked++;
					bases[i]='N';
					if(quals!=null){
						quals[i]=0;
					}
				}
				if(bases[i]=='N'){consecutiveBad=0;}
			}
		}
		
//		assert(toMark==0 && flag) : "toMark="+toMark+"card="+card+"len="+bases.length+"\n"+bs+"\n"+new String(bases)+"\n"+counts+"\nminCount="+minCount+"\n";
		
		return marked;
	}
	
	protected final boolean isSimilar(final int a, int loc1, int loc2, final IntList counts){
		loc1=Tools.max(loc1, 0);
		loc2=Tools.min(loc2, counts.size-1);
		for(int i=loc1; i<=loc2; i++){
			if(!isSimilar(a, counts.get(i))){return false;}
		}
		return true;
	}
	
	protected final boolean isSimilar(final int a, final int b){
		int min=Tools.min(a, b);
		int max=Tools.max(a, b);
		int dif=max-min;
		assert(dif>=0);
		return (dif<pathSimilarityConstant || dif<max*pathSimilarityFraction);
	}
	
	protected final boolean isError(final int a, int loc1, int loc2, final IntList counts){
		loc1=Tools.max(loc1, 0);
		loc2=Tools.min(loc2, counts.size-1);
		for(int i=loc1; i<=loc2; i++){
			if(!isError(a, counts.get(i))){return false;}
		}
		return true;
	}
	
	protected final boolean isError(final int high, final int low){
		return (low*errorMult1<high || (low<=errorLowerConst && high>=Tools.max(minCountCorrect, low*errorMult2)));
	}
	
	
	/*--------------------------------------------------------------*/
	/*----------------        Helper Methods        ----------------*/
	/*--------------------------------------------------------------*/
	
	protected final Kmer getKmer(byte[] bases, int loc, Kmer kmer){
		kmer.clear();
		for(int i=loc, lim=loc+kmer.kbig; i<lim; i++){
			byte b=bases[i];
			int x=AminoAcid.baseToNumber[b];
			if(x<0){return null;}
			kmer.addRightNumeric(x);
		}
		assert(kmer.len==kmer.kbig);
		return kmer;
	}
	
	protected final boolean isJunction(int rightMax, int rightSecond, int leftMax, int leftSecond){
		if(isJunction(rightMax, rightSecond)){return true;}
		return isJunction(leftMax, leftSecond);
	}
	
	private final boolean isJunction(int max, int second){
		if(second<1 || second*branchMult1<max || (second<=branchLowerConst && max>=Tools.max(minCountExtend, second*branchMult2))){
			return false;
		}
		if(verbose){outstream.println("Breaking because second-highest was too high:\n" +
				"max="+max+", second="+second+", branchMult1="+branchMult1+"\n" +
				"branchLowerConst="+branchLowerConst+", minCountExtend="+minCountExtend+", branchMult2="+branchMult2+"\n" +
				(second*branchMult1<max)+", "+(second<=branchLowerConst)+", "+(max>=Tools.max(minCountExtend, second*branchMult2)));}
		return true;
	}
	
	/*--------------------------------------------------------------*/
	/*----------------        Helper Classes        ----------------*/
	/*--------------------------------------------------------------*/
	
	private final class DumpKmersThread extends Thread {
		
		DumpKmersThread(){}
		
		public void run(){
			dumpKmersAsText();
		}
		
	}
	
	private final class MakeKhistThread extends Thread {
		
		MakeKhistThread(){}
		
		public void run(){
			makeKhist();
		}
	}
	
	/*--------------------------------------------------------------*/
	/*----------------            Fields            ----------------*/
	/*--------------------------------------------------------------*/
	
	abstract AbstractKmerTableSet tables();
	
//	int ways; //MUST be set by subclass
	/** Big kmer length */
	final int kbig;

	private ArrayList<Read> allContigs;
	private LongList allInserts;
	private long contigsBuilt=0;
	private long basesBuilt=0;
	private long longestContig=0;
	
	protected boolean extendThroughLeftJunctions=true;
	
	private boolean removeBubbles=false;
	private boolean removeDeadEnds=false;
	protected int maxShaveDepth=1;
	protected int shaveDiscardLen=150;
	protected int shaveExploreDist=100;
	
	protected int kmerRangeMin=0;
	protected int kmerRangeMax=Integer.MAX_VALUE;
	
	protected int processingMode=-1;

	private int extendLeft=-1;
	protected int extendRight=-1;
	
	/** Track kmer ownership */
	public final boolean useOwnership;
	
	public int maxContigLen=1000000000;
	public int minExtension=2;
	public int minContigLen=100;
	public float minCoverage=1;

	int trimEnds=0;

	int minCountSeed=3;

	protected int minCountExtend=2;
	protected float branchMult1=20;
	protected float branchMult2=3;
	private int branchLowerConst=3;
	
	private float errorMult1=60;
	private float errorMult2=3;
	private int errorLowerConst=3;//3 seems fine
	private int minCountCorrect=4;//5 is more conservative...
	private int pathSimilarityConstant=3;
	private float pathSimilarityFraction=0.3f;//0.3
	protected int errorExtensionPincer=5;//default 5; higher is more conservative
	protected int errorExtensionTail=9;//default 9; higher is more conservative
	
	public boolean showStats=true;
	
	/** Has this class encountered errors while processing? */
	public boolean errorState=false;
	
	/** Input reads to extend */
	private ArrayList<String> in1=new ArrayList<String>(), in2=new ArrayList<String>();
	/** Output extended reads */
	private ArrayList<String> out1=new ArrayList<String>(), out2=new ArrayList<String>();
	/** Output discarded reads */
	private ArrayList<String> outd1=new ArrayList<String>(), outd2=new ArrayList<String>();
	
//	/** Contig output file */
//	private String outContigs=null;
	/** Insert size histogram */
	private String outInsert=null;
	/** Kmer count output file */
	protected String outKmers=null;
	/** Histogram output file */
	protected String outHist=null;

	/** Histogram columns */
	protected int histColumns=2;
	/** Histogram rows */
	protected int histMax=100000;
	/** Print a histogram header */
	protected boolean histHeader=true;
	/** Histogram show rows with 0 count */
	protected boolean histZeros=false;
	
	protected boolean smoothHist=false;
	
	/** Maximum input reads (or pairs) to process.  Does not apply to references.  -1 means unlimited. */
	private long maxReads=-1;
	
	long readsIn=0;
	long basesIn=0;
	long readsOut=0;
	long basesOut=0;
	long lowqReads=0;
	long lowqBases=0;
	long basesExtended=0;
	long readsExtended=0;
	long readsCorrected=0;
	long basesCorrectedTail=0;
	long basesCorrectedPincer=0;
	long readsFullyCorrected=0;
	long readsDetected=0;
	long basesDetected=0;
	long readsMarked=0;
	long basesMarked=0;
	long readsDiscarded=0;
	long basesDiscarded=0;
	
	protected boolean ECC_PINCER=true;
	protected boolean ECC_TAIL=true;
	protected boolean ECC_ALL=false;
	/** Mark bases as bad if they are completely covered by kmers with a count below this */
	protected int MARK_BAD_BASES=0;
	/** Only mark bad bases that are adjacent to good bases */ 
	protected boolean MARK_DELTA_ONLY=true;
	
	/** Discard reads that cannot be assembled */
	protected boolean tossJunk=false;
	
	/** Discard reads with any kmer below this depth */
	protected int discardLowDepthReads=0;
	
	/*--------------------------------------------------------------*/
	/*----------------       ThreadLocal Temps      ----------------*/
	/*--------------------------------------------------------------*/
	
	protected final void initializeThreadLocals(){
		if(localLeftCounts.get()!=null){return;}
		localLeftCounts.set(new int[4]);
		localRightCounts.set(new int[4]);
		localLongList.set(new LongList());
		localIntList.set(new IntList());
		localByteBuilder.set(new ByteBuilder());
		localBitSet.set(new BitSet(300));
		localKmer.set(new Kmer(kbig));
	}
	
	protected ThreadLocal<int[]> localLeftCounts=new ThreadLocal<int[]>();
	protected ThreadLocal<int[]> localRightCounts=new ThreadLocal<int[]>();
	protected ThreadLocal<LongList> localLongList=new ThreadLocal<LongList>();
	protected ThreadLocal<IntList> localIntList=new ThreadLocal<IntList>();
	protected ThreadLocal<ByteBuilder> localByteBuilder=new ThreadLocal<ByteBuilder>();
	protected ThreadLocal<BitSet> localBitSet=new ThreadLocal<BitSet>();
	protected ThreadLocal<Kmer> localKmer=new ThreadLocal<Kmer>();
	
	/*--------------------------------------------------------------*/
	/*----------------       Final Primitives       ----------------*/
	/*--------------------------------------------------------------*/
	
	/** min kmer count to dump to text */
	protected int minToDump=1;
	
	/** Correct via kmers */
	private final boolean ecc;
	
	/** Correct via overlap */
	final boolean ecco;
	
	/** True iff java was launched with the -ea' flag */
	private final boolean EA;
	
	/** For numbering contigs */
	final AtomicLong contigNum=new AtomicLong(0);
	
	int contigPasses=16;
	double contigPassMult=1.7;
	
	/** For controlling access to tables for contig-building */
	final AtomicInteger nextTable[];
	
	/** For controlling access to victim buffers for contig-building */
	final AtomicInteger nextVictims[];
	
	/*--------------------------------------------------------------*/
	/*----------------         Static Fields        ----------------*/
	/*--------------------------------------------------------------*/
	
	/** Print messages to this stream */
	protected static PrintStream outstream=System.err;
	/** Permission to overwrite existing files */
	public static boolean overwrite=false;
	/** Permission to append to existing files */
	public static boolean append=false;
	/** Force output reads to stay in input order */
	public static boolean ordered=false;
	/** Print speed statistics upon completion */
	public static boolean showSpeed=true;
	/** Display progress messages such as memory usage */
	public static boolean DISPLAY_PROGRESS=true;
	/** Verbose messages */
	public static boolean verbose=false;
	/** Debugging verbose messages */
	public static boolean verbose2=false;
	/** Number of ProcessThreads */
	public static int THREADS=Shared.threads();
	/** Do garbage collection prior to printing memory usage */
	private static final boolean GC_BEFORE_PRINT_MEMORY=false;

	static boolean IGNORE_BAD_OWNER=false;
	
	public static final int contigMode=0;
	public static final int extendMode=1;
	public static final int correctMode=2;
	public static final int insertMode=3;
	public static final int discardMode=4;
	
	/** Explore codes */
	public static final int KEEP_GOING=0, DEAD_END=1, TOO_SHORT=2, TOO_LONG=3, TOO_DEEP=4, FORWARD_BRANCH=5, BACKWARD_BRANCH=6, LOOP=7;
	
	/** Extend codes */
	public static final int BAD_OWNER=11, BAD_SEED=12, BRANCH=13;
	
	public static final int STATUS_UNEXPLORED=0, STATUS_EXPLORED=1, STATUS_REMOVE=2, STATUS_KEEP=3;
	
}
