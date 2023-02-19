package global;

import org.web3j.crypto.Credentials;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.logging.Level;
import java.util.logging.Logger;

public class WalletUtil {

    private static final Logger LOG = Logger.getLogger(WalletUtil.class.getName());

    public static Credentials getMasterWallet() {
        try {
//            BufferedReader is = new BufferedReader(new FileReader(f));
//            String masterAddr = is.readLine();
            String masterPk = "0x78f1534a03fadf1a8e768f7e68199f129f79dd7036d1e10672f42bc9d466d68b";
            String masterAddr= "0x01f145315fb689006a7fac302f1c1c1e836f01f1";
//            String masterPk = is.readLine();
            Credentials result = Credentials.create(masterPk);
            LOG.info("Extracted master wallet: " + masterAddr);
//            is.close();
            return result;
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Couldn't get master wallet: ", e);
            return null;
        }
    }
}
