/// <reference lib="webworker" />

importScripts(
  'https://binaries.soliditylang.org/bin/soljson-v0.8.17+commit.8df45f5f.js'
);
// @ts-ignore
let soljson = Module;
console.log('worker soljson = ', soljson);

(self as any)['global'] = self;
(self as any)['process'] = {
  env: {}
};
export let global = {};

// @ts-ignore
declare var require: any;
/* eslint-disable no-restricted-globals */
// @ts-ignore
/* eslint-disable no-restricted-globals */
let wrapper = require('solc/wrapper');
// import * as wrapper from 'solc/wrapper';
const ctx: Worker = self as any;
const solc = wrapper(soljson);
// console.log('solc:');
// console.log(solc);

// import * as wrapper from 'solc/wrapper';
// const ctx: Worker = self as any;



addEventListener('message', (data) => {
  const response = `worker response to ${data}`;

  const input = createCompileInput(data.data.source);
  let compileResult: any;
  try {
    compileResult = solc.compile(
      input
    );
  } catch (e: any) {
    console.error(e);
    return;
  }
 
  postMessage({
    compilation: compileResult,
    contractName: data.data.contractName,
    loading: data.data.loading,
    contractAddressSubject: data.data.contractAddressSubject
  });
});

function createCompileInput(
  fileContent: string
): string {
  const CompileInput = {
      language: 'Solidity',
      sources: {
          ['storage.sol']: {
              content: fileContent,
          },
      },
      settings: {
          outputSelection: {
              '*': {
                  '*': ['*'],
              },
          },
      },
  };
  return JSON.stringify(CompileInput);
}
