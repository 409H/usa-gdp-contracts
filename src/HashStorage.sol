// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title A hash storage contract
contract HashStorage {
    address public owner;

    struct PeriodDetails {
        bytes32 pdfHash;    // sha256 of pdf
        string pdfLocation; // https location of pdf (ie: https://www.bea.gov/sites/default/files/2025-08/gdp2q25-2nd.pdf)
        uint256 gdp;        // Increments of tenths 
    }
    mapping(string => PeriodDetails) public gdpDetails;

    // Errors
    error NoAuthorisation();
    error OwnerCannotBeDead();
    error InvalidTimePeriod();
    error NoData();

    // Events
    event OwnershipTransferred(address oldOwner, address newOwner);
    event NewEntry(string indexed timePeriod, bytes32 hash);

    // Modifiers
    modifier onlyOwner()
    {
        if(msg.sender != owner) {
            revert NoAuthorisation();
        }

        _;
    }
    
    constructor(address _owner) 
    {
        owner = _owner;
    }

    /// @notice Change the owner of the contract. Owners can commit data to the storage
    /// @param _newOwner The address of the new owner
    /// @return true
    function transferOwnership(address _newOwner) 
        public 
        onlyOwner()
        returns(bool)
    {
        if(_newOwner == address(0)) {
            revert OwnerCannotBeDead();
        }

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
        return true;
    }

    /// @notice Commit data to the storage
    /// @param _timePeriod A descriptive time period about the data being committed (ex: 2025Q2)
    /// @param _pdfHash A SHA256 hash of the PDF that stores the details about the GDP
    /// @param _pdfLocation The HTTP location of the pdf (ie: https://www.bea.gov/sites/default/files/2025-08/gdp2q25-2nd.pdf)
    /// @param _gdp The GDP for this time period (increments of tenths)
    /// @return true
    function commit(string calldata _timePeriod, bytes32 _pdfHash, string memory _pdfLocation, uint256 _gdp) 
        public 
        onlyOwner()
        returns(bool)
    {
        if(!isValidTimePeriod(_timePeriod)) {
            revert InvalidTimePeriod();
        }

        emit NewEntry(_timePeriod, _pdfHash);
        gdpDetails[_timePeriod] = PeriodDetails(_pdfHash, _pdfLocation, _gdp);
        return true;
    }

    /// @notice Read GDP data for a time period (ie: 2025Q2)
    /// @param _timePeriod A descriptive time period about the data wanting to be read (ex: 2025Q2)
    /// @return The PDF hash, the PDF location, the GDP
    function read(string calldata _timePeriod)
        public
        view
        returns(PeriodDetails memory)
    {
        (bytes32 pdfHash, string memory pdfLocation, uint256 gdp) = this.gdpDetails(_timePeriod);
        if(pdfHash == 0) {
            revert NoData();
        }

        return HashStorage.PeriodDetails(
            pdfHash,
            pdfLocation,
            gdp
        );
    }

    /****
     * Helper functions
     */
    function isValidTimePeriod(string memory _input) 
        internal 
        pure 
        returns (bool) 
    {
        // Convert string to bytes for easier manipulation
        bytes memory inputBytes = bytes(_input);

        // Check if the length is exactly 6 (4 digits + Q + 1 digit)
        if (inputBytes.length != 6) {
            return false;
        }

        // Check if first 4 characters are digits (for the year)
        for (uint i = 0; i < 4; i++) {
            if (!_isDigit(inputBytes[i])) {
                return false;
            }
        }

        // Check if 5th character is 'Q'
        if (inputBytes[4] != bytes1("Q")) {
            return false;
        }

        // Check if 6th character is a digit between 1 and 4
        if (!_isValidQuarterDigit(inputBytes[5])) {
            return false;
        }

        // Optional: Validate year is within a reasonable range (e.g., 2000–2099)
        uint year = _bytesToUint(_substring(inputBytes, 0, 4));
        if (year < 2000 || year > 2099) {
            return false;
        }

        return true;
    }

    // Helper function to check if a byte is a digit (0-9)
    function _isDigit(bytes1 char) 
        internal 
        pure 
        returns (bool) 
    {
        return (char >= bytes1("0") && char <= bytes1("9"));
    }

    // Helper function to check if a byte is a valid quarter digit (1-4)
    function _isValidQuarterDigit(bytes1 char) 
        internal 
        pure 
        returns (bool) 
    {
        return (char >= bytes1("1") && char <= bytes1("4"));
    }

    // Helper function to extract a substring as bytes
    function _substring(bytes memory _data, uint start, uint len) 
        internal 
        pure 
        returns (bytes memory) 
    {
        bytes memory result = new bytes(len);
        for (uint i = 0; i < len; i++) {
            result[i] = _data[start + i];
        }
        return result;
    }

    // Helper function to convert a 4-byte string to uint (e.g., "2025" to 2025)
    function _bytesToUint(bytes memory _data) 
        internal 
        pure 
        returns (uint) 
    {
        uint result = 0;
        for (uint i = 0; i < _data.length; i++) {
            result = result * 10 + (uint8(_data[i]) - uint8(bytes1("0")));
        }
        return result;
    }
}
