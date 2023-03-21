abstract contract stFlip {
  function mint(address to, uint256 amount) external virtual returns (bool);
  address public minter;
}


contract Minter {
    // using SafeMath for uint256;
    address public gov;
    address public pendingGov;
    address public output;

    stFlip public stflip;
    IERC20 public flip;

    constructor(address stflip_, address output_, address gov_, address flip_) {
        stflip = stFlip(stflip_);
        output = output_;
        gov = gov_;
        flip = IERC20(flip_);
    }

    event NewPendingGov(address oldPendingGov, address newPendingGov);

    event NewGov(address oldGov, address newGov);

    event Mint(address to, uint256 amount);

    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }

    function _setPendingGov(address pendingGov_)
        external
        onlyGov
    {
        address oldPendingGov = pendingGov;
        pendingGov = pendingGov_;
        emit NewPendingGov(oldPendingGov, pendingGov_);
    }

    function _acceptGov()
        external
    {
        require(msg.sender == pendingGov, "!pending");
        address oldGov = gov;
        gov = pendingGov;
        pendingGov = address(0);
        emit NewGov(oldGov, gov);
    }

    function _setOutput(address output_)
        external
        onlyGov
    {
        output = output_;
    }

    function mint(address to, uint256 amount)
        external
        returns (bool)
    {
        // require(stflip.minter() == address(this), "this is not a valid mint contract");
        flip.transferFrom(msg.sender, output, amount);

        _mint(to, amount);
        return true;
    }

    function _mint(address to, uint256 amount)
        internal
    {
      stflip.mint(to, amount);
      emit Mint(to, amount);
    }
}
