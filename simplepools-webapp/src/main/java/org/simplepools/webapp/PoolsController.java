package org.simplepools.webapp;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.annotation.JsonAutoDetect;

import data.Blockchains;
import data.DatabaseService;

@RestController
public class PoolsController {

    // private Web3Service _web3service = Web3Service.INSTANCE;

    @GetMapping("/services/pools")
    protected PoolsResponse doGet(@RequestParam(value = "from") Long from,
                @RequestParam(value = "to") Long to,
                @RequestParam(value = "blockchain") String blockchain) {
        String provider = Blockchains.PROVIDER_FOR_BLOCKCHAIN.get(blockchain);
        if (provider == null) {
            throw new RuntimeException("Invalid blockchain: " + blockchain);
        }

        // BigInteger poolsCount = _web3service.getSimplePools().getPoolsCount().send();
        List pools = DatabaseService.INSTANCE.getPools(from, to, blockchain);
        List poolsMetadata = DatabaseService.INSTANCE.getPoolsMetadata(from, to, blockchain);
        long numberOfAllPools = DatabaseService.INSTANCE.getNumberOfPools(blockchain);
        PoolsResponse res = new PoolsResponse(pools, poolsMetadata, numberOfAllPools);
        return res;
    }
 
    @JsonAutoDetect(fieldVisibility = JsonAutoDetect.Visibility.ANY)
    public static class PoolsResponse {
       public List poolsOnPage;
       public List poolsMedatada;
       public long totalNumberOfPools;
       PoolsResponse(List poolsOnPage, List poolsMetadata, long totalNumberOfPools) {
          this.poolsOnPage = poolsOnPage;
          this.poolsMedatada = poolsMetadata;
          this.totalNumberOfPools = totalNumberOfPools;
       }
    }
}
