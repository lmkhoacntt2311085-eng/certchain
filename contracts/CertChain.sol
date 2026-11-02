// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CertChain {
    struct Cert {
        string ipfsCid;
        string student;
        string course;
        address issuer;
        uint256 issuedAt;
        bool revoked;
    }

    address public owner;
    mapping(address => bool) public isIssuer;
    mapping(bytes32 => Cert) private certs;

    event IssuerAdded(address indexed issuer);
    event IssuerRemoved(address indexed issuer);
    event CertificateIssued(bytes32 indexed hash, address indexed issuer, string ipfsCid);
    event CertificateRevoked(bytes32 indexed hash);

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    modifier onlyIssuer() { require(isIssuer[msg.sender], "Not issuer"); _; }

    constructor() {
        owner = msg.sender;
        isIssuer[msg.sender] = true;
    }

    function addIssuer(address a) external onlyOwner {
        isIssuer[a] = true;
        emit IssuerAdded(a);
    }

    function removeIssuer(address a) external onlyOwner {
        isIssuer[a] = false;
        emit IssuerRemoved(a);
    }

    function issueCertificate(
        bytes32 hash,
        string calldata ipfsCid,
        string calldata student,
        string calldata course
    ) external onlyIssuer {
        require(certs[hash].issuedAt == 0, "Already issued");
        certs[hash] = Cert(ipfsCid, student, course, msg.sender, block.timestamp, false);
        emit CertificateIssued(hash, msg.sender, ipfsCid);
    }

    function revokeCertificate(bytes32 hash) external {
        Cert storage c = certs[hash];
        require(c.issuedAt != 0, "Not found");
        require(c.issuer == msg.sender || msg.sender == owner, "Not allowed");
        c.revoked = true;
        emit CertificateRevoked(hash);
    }

    function verify(bytes32 hash) external view returns (
        bool exists, bool revoked, string memory ipfsCid,
        string memory student, string memory course,
        address issuer, uint256 issuedAt
    ) {
        Cert storage c = certs[hash];
        return (c.issuedAt != 0, c.revoked, c.ipfsCid, c.student, c.course, c.issuer, c.issuedAt);
    }
}
