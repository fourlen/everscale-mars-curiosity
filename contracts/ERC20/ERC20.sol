// SPDX-License-Identifier: MIT

pragma ton-solidity >=0.42.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint128) private _balances;

    mapping (address => mapping (address => uint128)) private _allowances;

    uint128 private _totalSupply;

    string static private _name;
    string static private _symbol;

    constructor() public {
        tvm.accept();
    }

    function name() public view virtual override responsible returns (string) {
        return _name;
    }

    function symbol() public view virtual override responsible returns (string) {
        return _symbol;
    }

    function decimals() public view virtual override responsible returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override responsible returns (uint128) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override responsible returns (uint128) {
        return _balances[account];
    }

    function transfer(address recipient, uint128 amount) public virtual override responsible functionID(12) returns (bool) {
        _transfer(_msgSender(), recipient, amount);

        // return change
        tvm.rawReserve(address(this).balance - msg.value, 0);
        return{value: 0, flag: 128} true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override responsible returns (uint128) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint128 amount) public virtual override responsible returns (bool) {
        _approve(_msgSender(), spender, amount);

        // return change
        tvm.rawReserve(address(this).balance - msg.value, 0);
        return{value: 0, flag: 128} true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint128 amount) public virtual override responsible functionID(26) returns (bool) {
        _transfer(sender, recipient, amount);

        uint128 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, 101, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        // return change
        tvm.rawReserve(address(this).balance - msg.value, 0);
        return{value: 0, flag: 128} true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint128 addedValue) public virtual responsible returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);

        // return change
        tvm.rawReserve(address(this).balance - msg.value, 0);
        return{value: 0, flag: 128} true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint128 subtractedValue) public virtual responsible returns (bool) {
        uint128 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, 102, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        // return change
        tvm.rawReserve(address(this).balance - msg.value, 0);
        return{value: 0, flag: 128} true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint128 amount) internal virtual {
        require(sender != address(0), 103, "ERC20: transfer from the zero address");
        require(recipient != address(0), 103, "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint128 senderBalance = _balances[sender];
        require(senderBalance >= amount, 104, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint128 amount) internal virtual {
        require(account != address(0), 105, "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint128 amount) internal virtual {
        require(account != address(0), 106, "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint128 accountBalance = _balances[account];
        require(accountBalance >= amount, 107, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint128 amount) internal virtual {
        require(owner != address(0), 108, "ERC20: approve from the zero address");
        require(spender != address(0), 109, "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint128 amount) internal virtual { }
}
