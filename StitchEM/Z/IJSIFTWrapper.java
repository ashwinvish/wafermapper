import ij.process.ImageProcessor;
import mpicbg.imagefeatures.Feature;
import mpicbg.imagefeatures.FloatArray2DSIFT;
import mpicbg.ij.SIFT;
import mpicbg.ij.FeatureTransform;
import mpicbg.models.PointMatch;

public class IJSIFTWrapper {
	final public void main(String args[]) {
		// Feature (mpicbg.imagefeatures.Feature) container
		final private List< Feature > fs1 = new ArrayList< Feature >();
		final private List< Feature > fs2 = new ArrayList< Feature >();

		// SIFT feature detector parameters (mpicbg.imagefeatures.FloatArray2DSIFT)
		final FloatArray2DSIFT.Param sift = new FloatArray2DSIFT.Param();

		// SIFT feature detector class (mpicbg.ij.SIFT)
		final SIFT ijSIFT = new SIFT( sift );

		// Method to run feature extraction
		ijSIFT.extractFeatures( imp1.getProcessor(), fs1 );
		ijSIFT.extractFeatures( imp2.getProcessor(), fs2 );

		// Match container (mpicbg.models.PointMatch)
		final List< PointMatch > candidates = new ArrayList< PointMatch >();

		// Nearest neighbor feature matcher (mpicbg.ij.FeatureTransform)
		// p.rod = 2; // closest/next_closest_ratio
		FeatureTransform.matchFeatures( fs1, fs2, candidates, 2 );

		System.out.println(candidates.size());
	}
}
