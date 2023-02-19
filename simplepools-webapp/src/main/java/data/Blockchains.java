package data;

import java.util.HashMap;
import java.util.Map;

public class Blockchains {

   public static Map<String, String> PROVIDER_FOR_BLOCKCHAIN = new HashMap<>();
   static {
      PROVIDER_FOR_BLOCKCHAIN.put("eth", "https://rpc.ankr.com/eth");
      PROVIDER_FOR_BLOCKCHAIN.put("bsc", "https://rpc.ankr.com/bsc");
      PROVIDER_FOR_BLOCKCHAIN.put("polygon", "https://rpc.ankr.com/polygon");
      PROVIDER_FOR_BLOCKCHAIN.put("avalanche", "https://rpc.ankr.com/avalanche-c");
      PROVIDER_FOR_BLOCKCHAIN.put("bttc", "https://rpc.ankr.com/bttc");
      PROVIDER_FOR_BLOCKCHAIN.put("fantom", "https://rpc.ankr.com/fantom");
      PROVIDER_FOR_BLOCKCHAIN.put("optimism", "https://rpc.ankr.com/optimism");
      PROVIDER_FOR_BLOCKCHAIN.put("gnosis", "https://rpc.ankr.com/gnosis");
      PROVIDER_FOR_BLOCKCHAIN.put("sepolia", "https://rpc2.sepolia.org/");
   }
}
