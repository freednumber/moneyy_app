// MODIFIED FOR BALANCE STYLE
Widget _buildNetWorthCard(MoneyModel model, bool isDark, bool isCompact) {
  final positive = model.netWorth >= 0;
  return Center(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 22 : 24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 22 : 32, // Enlarged for more visual impact
            vertical: isCompact ? 18 : 24, // Enlarged
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                positive ? Color(0xFF195547).withOpacity(0.92) : Color(0xFF742222).withOpacity(0.92),
                positive ? Color(0xFF266973).withOpacity(0.94) : Color(0xFF8B2D2D).withOpacity(0.94)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isCompact ? 22 : 24),
            border: Border.all(
              color: positive ? Color(0xFF38F9D7).withOpacity(0.17) : Color(0xFFC20909).withOpacity(0.17),
              width: 2.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                positive ? Icons.account_balance_wallet_rounded : Icons.do_not_disturb_alt_rounded,
                color: Colors.white,
                size: isCompact ? 26 : 32,
              ),
              SizedBox(width: isCompact ? 18 : 26),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Saldo Netto',
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.90),
                    ),
                  ),
                  SizedBox(height: isCompact ? 8 : 12),
                  Text(
                    model.format(model.netWorth),
                    style: TextStyle(
                      fontSize: isCompact ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1.0,
                      shadows: [
                        Shadow(
                          color: positive ? Color(0xFF38F9D7).withOpacity(0.4) : Color(0xFFE81A1A).withOpacity(0.35),
                          blurRadius: 16,
                          offset: Offset(0,2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
