const { ethers } = require("hardhat");
const { expect } = require("chai");
const { getContractAddress } = require("@ethersproject/address");

describe("[Challenge] Safe Miners", function () {
    let deployer, attacker;

    const DEPOSIT_TOKEN_AMOUNT = ethers.utils.parseEther("2000042");
    const DEPOSIT_ADDRESS = "0x79658d35aB5c38B6b988C23D02e0410A380B8D5c";

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();

        // Deploy Damn Valuable Token contract
        this.token = await (
            await ethers.getContractFactory("DamnValuableToken", deployer)
        ).deploy();

        // Deposit the DVT tokens to the address
        await this.token.transfer(DEPOSIT_ADDRESS, DEPOSIT_TOKEN_AMOUNT);

        // Ensure initial balances are correctly set
        expect(await this.token.balanceOf(DEPOSIT_ADDRESS)).eq(
            DEPOSIT_TOKEN_AMOUNT
        );
        expect(await this.token.balanceOf(attacker.address)).eq("0");
    });

    it("Exploit", async function () {
        /** CODE YOUR EXPLOIT HERE */
        for (let nonce = 0; nonce < 100; nonce++) {
            const futureAddress1 = getContractAddress({
                from: attacker.address,
                nonce: nonce,
            });

            for (let nonce2 = 0; nonce2 < 100; nonce2++) {
                const futureAddress2 = getContractAddress({
                    from: futureAddress1,
                    nonce: nonce2,
                });
                if (futureAddress2 == DEPOSIT_ADDRESS)
                    console.log(`Found contract at nonce: ${nonce},${nonce2}`);
            }
        }

        // Create empty transactions to get nonce up
    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        // The attacker took all tokens available in the deposit address
        expect(await this.token.balanceOf(DEPOSIT_ADDRESS)).to.eq("0");
        expect(await this.token.balanceOf(attacker.address)).to.eq(
            DEPOSIT_TOKEN_AMOUNT
        );
    });
});
