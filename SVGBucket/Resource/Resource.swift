import Foundation

public class Resource {
    
    public static func initResource(){
        guard let url = Bundle(for: Resource.self).url(forResource: "ImageIcon", withExtension: "bundle") else { return  }
        guard let bundle =  Bundle(url: url) else { return }
        let _ = ImageiconSVGBReader.shared.setup(bundle: bundle)
    }
}
