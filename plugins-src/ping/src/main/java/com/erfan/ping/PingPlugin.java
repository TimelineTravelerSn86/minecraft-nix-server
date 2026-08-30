package com.erfan.ping;

import org.bukkit.Bukkit;
import org.bukkit.ChatColor;
import org.bukkit.command.Command;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;

public class PingPlugin extends JavaPlugin {

    @Override
    public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
        if (args.length == 0) {
            if (!(sender instanceof Player)) {
                sender.sendMessage("Console has no ping. Try /ping <player>.");
                return true;
            }
            Player player = (Player) sender;
            sender.sendMessage(ChatColor.GRAY + "Your ping: " + ChatColor.WHITE + player.getPing() + "ms");
            return true;
        }

        Player target = Bukkit.getPlayerExact(args[0]);
        if (target == null) {
            sender.sendMessage(ChatColor.RED + "No online player named '" + args[0] + "'.");
            return true;
        }

        sender.sendMessage(ChatColor.GRAY + target.getName() + "'s ping: " + ChatColor.WHITE + target.getPing() + "ms");
          return true;
    }
}

