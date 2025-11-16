// MODIFIED QUICK ADD SECTION FOR SWYPE-STYLE
Widget _buildQuickAddSection(
  BuildContext context,
  MoneyModel model,
  bool isDark,
  bool isCompact,
) {
  final mostUsed = _getMostUsedCategories(model);
  return ClipRRect(
    borderRadius: BorderRadius.circular(isCompact ? 22 : 26),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 22,
          vertical: isCompact ? 14 : 18,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF184C38).withOpacity(0.93), Color(0xFF1B5A40).withOpacity(0.95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isCompact ? 22 : 26),
          border: Border.all(
            color: Color(0xFF38F9D7).withOpacity(0.15),
            width: 2.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Color(0xFF38F9D7), size: isCompact ? 22 : 28),
                SizedBox(width: isCompact ? 16 : 20),
                Text(
                  'Aggiunte Veloci',
                  style: TextStyle(
                    fontSize: isCompact ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.96),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 16 : 18),
            Wrap(
              spacing: isCompact ? 14 : 18,
              runSpacing: isCompact ? 14 : 18,
              children: mostUsed.map((cat) {
                final style = model.getTransactionStyle(cat);
                final isIncome = model.incomeCats.contains(cat);
                final lastUsed = _getLastUsedDate(model, cat);
                return InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _showQuickEntryDialog(context, cat, isIncome);
                  },
                  borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 16 : 20,
                      vertical: isCompact ? 12 : 14,
                    ),
                    decoration: BoxDecoration(
                      color: style.color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
                      border: Border.all(
                        color: style.color.withOpacity(0.29),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: style.color.withOpacity(0.18),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(style.icon, color: Colors.white, size: isCompact ? 22 : 28),
                        SizedBox(width: isCompact ? 12 : 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isCompact ? 15 : 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: isCompact ? 2 : 5),
                            Text(
                              lastUsed,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isCompact ? 10.5 : 13,
                                color: Colors.white.withOpacity(0.77),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
