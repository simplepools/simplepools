package org.simplepools;

import com.fasterxml.jackson.annotation.JsonAutoDetect;
import data.Blockchains;
import data.DatabaseService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mypackage.HttpUtil;
import mypackage.Web3Service;
import org.simplepools.smartcontract.SimplePools;


import java.io.IOException;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;

public class PoolsServlet extends jakarta.servlet.http.HttpServlet {

   private Web3Service _web3service = Web3Service.INSTANCE;

   @Override
   protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
      try {
         long from = Long.parseLong(req.getParameter("from"));
         long to = Long.parseLong(req.getParameter("to"));
         String blockchain = req.getParameter("blockchain");
         String provider = Blockchains.PROVIDER_FOR_BLOCKCHAIN.get(blockchain);
         if (provider == null) {
            throw new RuntimeException("Invalid blockchain: " + blockchain);
         }

         // TODO Get pools from local database, not blockchain directly
         // Check currently synced transaction index in db and update db with pools
         // BigInteger poolsCount = _web3service.getSimplePools().getPoolsCount().send();
         List pools = DatabaseService.INSTANCE.getPools(from, to, blockchain);
         List poolsMetadata = DatabaseService.INSTANCE.getPoolsMetadata(from, to, blockchain);
         long numberOfAllPools = DatabaseService.INSTANCE.getNumberOfPools(blockchain);
         PoolsResponse res = new PoolsResponse(pools, poolsMetadata, numberOfAllPools);
         HttpUtil.postResponse(resp, res);
      } catch (Exception e) {
         throw new IOException(e);
      }
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
