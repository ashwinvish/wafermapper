import ij.plugin.PlugIn;
import ij.*;
import ij.io.*;
import java.io.*;


public class StitchWaferMapperMontageDirectory_PlugIn implements PlugIn {
	/**
	 * This method gets called by ImageJ / Fiji.
	 *
	 * @param arg can be specified in plugins.config
	 */
	public void run(String arg) {
		//Put in separator to make it esier to read log
		IJ.log(" ");
		IJ.log("************************************************************************************");
		IJ.log("*** START: StitchWaferMapperMontageDirectory_PlugIn ***");
		DirectoryChooser dc = new DirectoryChooser("Choose montage directory...");
		String DirectorySrting = dc.getDirectory();
		IJ.log("User choose directory: " + DirectorySrting);
		
		//Go through all files in directory until first tile file is found
		File dir = new File(DirectorySrting);
		String[] children = dir.list();
		String filename = "";
		Boolean IsFoundFirstTileFile = false;
		String FileNamePostfix = "";
		Integer MaxRow = 1;
		Integer MaxCol = 1;
		if (children == null) {
		    // Either dir does not exist or is not a directory
		    IJ.log("Either dir does not exist or is not a directory. Quitting...");
		    return;
		} 
		
		for (int i=0; i<children.length; i++) {
			filename = children[i];
			if (filename.startsWith("Tile_r1-c1_") && filename.endsWith(".tif")) {
				IsFoundFirstTileFile = true;
				FileNamePostfix = filename.substring(11,filename.length());		
			}	   

			if (filename.startsWith("Tile_r") && filename.endsWith(".tif")) {
				String RowString = filename.substring(6,filename.indexOf("-c"));
				String ColString = filename.substring(filename.indexOf("-c")+2, filename.indexOf("_", filename.indexOf("-c")));
				IJ.log("RowString = " + RowString + ", ColString = " + ColString);
				if (Integer.parseInt( RowString ) > MaxRow) {
					MaxRow = Integer.parseInt( RowString );
				}
				if (Integer.parseInt( ColString ) > MaxCol) {
					MaxCol = Integer.parseInt( ColString );
				}
					
				

			}
		}
		

		if (IsFoundFirstTileFile) {			
			IJ.log("FileNamePostfix = " + FileNamePostfix);
		} else {
			IJ.log("Could not find first tile file. Quitting... ");
			return;
		}

		IJ.log("MaxRow = " + MaxRow + ", MaxCol = " + MaxCol);

		String PromptString = "(rows, cols) = (" + MaxRow + ", " + MaxCol + "). " + "What was the percent overlap?";
		double PercentOverlap = IJ.getNumber(PromptString, 15);

		IJ.log("PercentOverlap = " + PercentOverlap);
		

		//String DirectorySrting = "F:\\JM_YR1C_Data\\TestMontage";
		String CommandString = "Stitch Grid of Images";
		String ParamString_Part1 = "grid_size_x=" + MaxCol + " grid_size_y=" + MaxRow + " overlap=" + PercentOverlap + " "; 
		String ParamString_Part2 = "directory=" + DirectorySrting + " "; 
		String ParamString_Part3 = "file_names=Tile_r{y}-c{x}_" + FileNamePostfix + " "; //_w010_sec1.tif ";
		String ParamString_Part4 = "rgb_order=rgb output_file_name=TileConfiguration.txt ";
		String ParamString_Part5 = "start_x=1 start_y=1 start_i=1 channels_for_registration=[Red, Green and Blue] ";
		String ParamString_Part6 = "fusion_method=[Linear Blending] fusion_alpha=1.50 regression_threshold=0.30 max/avg_displacement_threshold=2.50 ";
		String ParamString_Part7 = "absolute_displacement_threshold=3.50 compute_overlap";
		String ParamString = ParamString_Part1 + ParamString_Part2 + ParamString_Part3 + ParamString_Part4 + ParamString_Part5 + ParamString_Part6 + ParamString_Part7;
		IJ.run(CommandString, ParamString);
	
	}
}