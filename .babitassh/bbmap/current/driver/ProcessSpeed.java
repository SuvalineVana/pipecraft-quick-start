package driver;

import fileIO.TextFile;

/**
 * For BBMerge comparison data collation
 * @author Brian Bushnell
 * @date Feb 28, 2016
 *
 */
public class ProcessSpeed {
	
	public static void main(String[] args){
		
		String fname=args[0];
		TextFile tf=new TextFile(fname);
		for(String line=tf.nextLine(); line!=null; line=tf.nextLine()){
			if(line.startsWith("***")){
				System.out.println(line);
			}else if(line.startsWith("real")){
				String time=line.split("\t")[1];
				double seconds=toSeconds(time);
				System.out.println(String.format("%.3f", seconds));
			}else if(line.startsWith("Correct:")){
				System.out.print(line.split("\\p{javaWhitespace}+")[2]+"\t");
			}else if(line.startsWith("Incorrect:")){
				System.out.print(line.split("\\p{javaWhitespace}+")[2]+"\n");
			}
//				Correct:                	99.72071%	15941011 reads
//				Incorrect:              	0.27929%	44646 reads
//				Too Short:              	0.02666%	4262 reads
//				Too Long:               	0.25263%	40384 reads
//				SNR:                    	25.539
			
			
			
		}
		
	}
	
	public static double toSeconds(String s){
		s=s.replaceAll("s", "");
		String[] split=s.split("m");
		String seconds=split[1], minutes=split[0];
		return 60*Double.parseDouble(minutes)+Double.parseDouble(seconds);
	}
	
}
